"""
Backfill spesifikasi game yang masih kosong di database production.

Banyak game (hasil import cepat via /games/search) hanya menyimpan judul +
banner tanpa detail spesifikasi, sehingga tidak bisa dievaluasi kelayakannya
dan hilang dari widget "playable" di beranda.

Alur:
  1. Ambil seluruh game dari /api/games/all.
  2. Saring yang min_specs (ram & storage) masih kosong.
  3. Untuk tiap steam_app_id, ambil pc_requirements resmi dari Steam appdetails.
  4. Kirim ke /api/games/scrape-v2 (updateOrCreate by steam_app_id) agar
     kolom spesifikasi terisi.

Pakai: python backfill_specs.py [maks_jumlah]
  contoh: python backfill_specs.py 50   (default: semua yang kosong)
"""

import sys
import re
import time
import html as html_lib
import os
import requests

BASE_URL = "https://game-checker-bqhhhae0b3b4dca3.eastasia-01.azurewebsites.net/api"
ALL_GAMES_URL = f"{BASE_URL}/games/all"
SCRAPE_URL = f"{BASE_URL}/games/scrape-v2"
DETAILS_URL = "https://store.steampowered.com/api/appdetails"

HEADERS = {"User-Agent": "GameChecker/1.0 (spec backfill)"}


def _angka_gb(teks: str):
    """Ekstrak angka GB dengan toleransi format berbeda (8GB, 8 GB, 8.5 GB)"""
    m = re.search(r"(\d+(?:\.\d+)?)\s*GB", teks, re.IGNORECASE)
    return int(float(m.group(1))) if m else None


def _pisah_daftar(teks: str) -> list[str]:
    """Pisah teks jadi list CPU/GPU, toleran terhadap format berbeda"""
    # Bersihkan HTML entities yang lolos
    teks = teks.replace('&nbsp;', ' ').replace('&amp;', '&')
    # Split by "or", koma, slash, atau "/"
    bagian = re.split(r'\s+or\s+|,|/|\bor\b', teks, flags=re.IGNORECASE)
    hasil = [b.strip(" .;()") for b in bagian if b.strip(" .;()")]
    return hasil[:6]  # Max 6 items untuk hindari noise


def parse_requirements(raw_html: str) -> dict:
    """Parse pc_requirements HTML dengan toleransi lebih tinggi terhadap variasi format"""
    spec = {"os": None, "cpu": [], "ram_gb": None, "gpu": [], "storage_gb": None}
    if not raw_html:
        return spec

    # Ekstrak semua <li> items
    for li in re.findall(r"<li>(.*?)</li>", raw_html, re.IGNORECASE | re.DOTALL):
        teks = html_lib.unescape(re.sub(r"<[^>]+>", " ", li)).strip()
        if ":" not in teks:
            continue
        label, _, value = teks.partition(":")
        label = label.strip().lower()
        value = re.sub(r"\s+", " ", value).strip()
        if not value:
            continue

        # OS - cari label yang mengandung "os" atau "operating system"
        if ("os" in label or "operating" in label) and spec["os"] is None:
            spec["os"] = value

        # CPU - cari "processor", "cpu"
        elif ("processor" in label or "cpu" in label) and not spec["cpu"]:
            spec["cpu"] = _pisah_daftar(value)

        # RAM/Memory - cari "memory", "ram"
        elif ("memory" in label or "ram" in label) and spec["ram_gb"] is None:
            spec["ram_gb"] = _angka_gb(value)

        # GPU - cari "graphics", "video", "gpu", "video card"
        elif ("graphics" in label or "video" in label or "gpu" in label) and not spec["gpu"]:
            spec["gpu"] = _pisah_daftar(value)

        # Storage - cari "storage", "hard drive", "hard disk", "hdd", "available space"
        elif ("storage" in label or "hard drive" in label or "hard disk" in label or
              "hdd" in label or "available space" in label) and spec["storage_gb"] is None:
            spec["storage_gb"] = _angka_gb(value)

    # FALLBACK: bila format tidak pakai <li> (mis. blok <p> atau teks polos),
    # coba tangkap label:value langsung dari teks bersih. Banyak game lama /
    # indie menulis requirements tanpa struktur list.
    if spec["ram_gb"] is None and spec["storage_gb"] is None:
        teks_bersih = html_lib.unescape(re.sub(r"<[^>]+>", " ", raw_html))
        teks_bersih = re.sub(r"\s+", " ", teks_bersih)

        if spec["os"] is None:
            m = re.search(r"OS\s*\*?\s*:\s*([^,;]+?)(?=\s+(?:Processor|CPU|Memory|RAM|Graphics|Video|Storage|Hard|DirectX|Sound)\s*:|$)", teks_bersih, re.IGNORECASE)
            if m:
                spec["os"] = m.group(1).strip()
        if not spec["cpu"]:
            m = re.search(r"(?:Processor|CPU)\s*:\s*(.+?)(?=\s+(?:Memory|RAM|Graphics|Video|Storage|Hard|DirectX|Sound|OS)\s*:|$)", teks_bersih, re.IGNORECASE)
            if m:
                spec["cpu"] = _pisah_daftar(m.group(1).strip())
        if spec["ram_gb"] is None:
            m = re.search(r"(?:Memory|RAM)\s*:\s*([^:]*?GB[^:]*?)(?=\s+\w+\s*:|$)", teks_bersih, re.IGNORECASE)
            if m:
                spec["ram_gb"] = _angka_gb(m.group(1))
        if not spec["gpu"]:
            m = re.search(r"(?:Graphics|Video)\s*:\s*(.+?)(?=\s+(?:Memory|RAM|Storage|Hard|DirectX|Sound|OS|Processor|CPU)\s*:|$)", teks_bersih, re.IGNORECASE)
            if m:
                spec["gpu"] = _pisah_daftar(m.group(1).strip())
        if spec["storage_gb"] is None:
            m = re.search(r"(?:Storage|Hard Drive|Hard Disk|HDD)\s*:\s*([^:]*?GB[^:]*?)(?=\s+\w+\s*:|$)", teks_bersih, re.IGNORECASE)
            if m:
                spec["storage_gb"] = _angka_gb(m.group(1))

    return spec


def ambil_detail(appid: str) -> dict | None:
    r = requests.get(
        DETAILS_URL,
        params={"appids": appid, "l": "english"},
        headers=HEADERS,
        timeout=30,
    )
    if r.status_code != 200:
        return None
    payload = r.json().get(str(appid), {})
    if not payload.get("success"):
        return None
    data = payload["data"]
    if data.get("type") != "game":
        return None
    req = data.get("pc_requirements") or {}
    if isinstance(req, list):
        req = {}
    return {
        "minimum": parse_requirements(req.get("minimum", "")),
        "recommended": parse_requirements(req.get("recommended", "")),
        "name": data.get("name"),
    }


def perlu_backfill(game: dict) -> bool:
    ms = game.get("min_specs")
    if not isinstance(ms, dict):
        return True
    return ms.get("ram") in (None, 0) and ms.get("storage") in (None, 0)


def kirim(appid: str, nama: str, minimum: dict, recommended: dict) -> bool:
    payload = {
        "app_id": appid,
        "game_name": nama,
        "minimum": minimum,
        "recommended": recommended,
        "spec_source": "steam",  # Tandai bahwa data berasal dari Steam
    }
    headers = dict(HEADERS)
    token = os.getenv("SCRAPER_TOKEN")
    if token:
        headers["X-Scraper-Token"] = token
    r = requests.post(SCRAPE_URL, json=payload, headers=headers, timeout=30)
    return r.status_code == 201


def main():
    maks = int(sys.argv[1]) if len(sys.argv) > 1 else 0  # 0 = semua

    print("Mengambil daftar game dari production...")
    r = requests.get(ALL_GAMES_URL, headers=HEADERS, timeout=60)
    r.raise_for_status()
    games = r.json().get("data", [])
    kosong = [g for g in games if g.get("steam_app_id") and perlu_backfill(g)]
    if maks > 0:
        kosong = kosong[:maks]

    print(f"Total game: {len(games)} | Perlu backfill: {len(kosong)}\n")

    sukses = 0
    dilewati = 0
    for i, game in enumerate(kosong, 1):
        appid = str(game["steam_app_id"])
        judul_lama = game.get("title") or f"Steam Game {appid}"
        detail = ambil_detail(appid)

        if detail is None:
            print(f"[{i}/{len(kosong)}] {judul_lama[:40]:40} (appid {appid}) -> tanpa detail, dilewati")
            dilewati += 1
            time.sleep(1.0)
            continue

        minimum = detail["minimum"]
        recommended = detail["recommended"]
        # Hanya kirim bila Steam benar-benar memberi angka ram/storage minimum.
        if minimum["ram_gb"] is None and minimum["storage_gb"] is None:
            print(f"[{i}/{len(kosong)}] {judul_lama[:40]:40} (appid {appid}) -> Steam tak punya spec, dilewati")
            dilewati += 1
            time.sleep(1.0)
            continue

        nama = detail["name"] or judul_lama
        ok = kirim(appid, nama, minimum, recommended)
        status = "OK" if ok else "GAGAL"
        print(
            f"[{i}/{len(kosong)}] {nama[:40]:40} | RAM {minimum['ram_gb']}GB | "
            f"Storage {minimum['storage_gb']}GB -> {status}"
        )
        if ok:
            sukses += 1
        time.sleep(1.2)

    print(f"\nSelesai. {sukses} terisi, {dilewati} dilewati, dari {len(kosong)} kandidat.")


if __name__ == "__main__":
    main()

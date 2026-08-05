"""
Importer katalog awal dari Steam ASLI (bukan data lokal/buatan).

Alur:
  1. Ambil daftar game TERPOPULER dari Steam Charts (GetMostPlayedGames) -> terurut by peak players.
  2. Untuk tiap appid, ambil detail resmi via store appdetails (nama, tipe, pc_requirements).
  3. Parse HTML pc_requirements menjadi os/cpu/gpu/ram_gb/storage_gb.
  4. Kirim ke endpoint Laravel /api/games/scrape-v2 (updateOrCreate by steam_app_id).

Pakai: python import_top_steam.py [jumlah]
  contoh: python import_top_steam.py 25
"""

import sys
import re
import time
import html as html_lib
import requests

# Endpoint production (Azure). Ganti via argumen ke-2 bila perlu.
LARAVEL_URL = "https://game-checker-bqhhhae0b3b4dca3.eastasia-01.azurewebsites.net/api/games/scrape-v2"
CHARTS_URL = "https://api.steampowered.com/ISteamChartsService/GetMostPlayedGames/v1/"
DETAILS_URL = "https://store.steampowered.com/api/appdetails"

HEADERS = {"User-Agent": "GameChecker/1.0 (catalog importer)"}


def ambil_top_appids(jumlah: int) -> list[int]:
    """Daftar appid game paling banyak dimainkan, terurut peringkat."""
    r = requests.get(CHARTS_URL, headers=HEADERS, timeout=30)
    r.raise_for_status()
    ranks = r.json()["response"]["ranks"]
    return [row["appid"] for row in ranks[:jumlah]]


def _angka_gb(teks: str):
    """Ambil angka GB pertama dari teks, contoh '8 GB RAM' -> 8."""
    m = re.search(r"(\d+)\s*GB", teks, re.IGNORECASE)
    return int(m.group(1)) if m else None


def _pisah_daftar(teks: str) -> list[str]:
    """Pecah string cpu/gpu jadi list, buang bagian kosong."""
    bagian = re.split(r"\s+or\s+|,|/|\bor\b", teks, flags=re.IGNORECASE)
    hasil = [b.strip(" .;") for b in bagian if b.strip(" .;")]
    return hasil[:6]


def parse_requirements(raw_html: str) -> dict:
    """Ubah HTML pc_requirements Steam jadi dict os/cpu/ram_gb/gpu/storage_gb."""
    spec = {"os": None, "cpu": [], "ram_gb": None, "gpu": [], "storage_gb": None}
    if not raw_html:
        return spec

    # Ambil tiap butir <li>Label: Value</li>
    for li in re.findall(r"<li>(.*?)</li>", raw_html, re.IGNORECASE | re.DOTALL):
        teks = html_lib.unescape(re.sub(r"<[^>]+>", " ", li)).strip()
        if ":" not in teks:
            continue
        label, _, value = teks.partition(":")
        label = label.strip().lower()
        value = re.sub(r"\s+", " ", value).strip()
        if not value:
            continue

        if "os" in label and spec["os"] is None:
            spec["os"] = value
        elif ("processor" in label or "cpu" in label) and not spec["cpu"]:
            spec["cpu"] = _pisah_daftar(value)
        elif "memory" in label and spec["ram_gb"] is None:
            spec["ram_gb"] = _angka_gb(value)
        elif ("graphics" in label or "video" in label or "gpu" in label) and not spec["gpu"]:
            spec["gpu"] = _pisah_daftar(value)
        elif ("storage" in label or "hard drive" in label or "hard disk" in label) and spec["storage_gb"] is None:
            spec["storage_gb"] = _angka_gb(value)

    return spec


def ambil_detail(appid: int) -> dict | None:
    """Ambil nama + pc_requirements dari appdetails; None jika bukan game."""
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
    if isinstance(req, list):  # kadang [] saat kosong
        req = {}
    return {
        "app_id": str(appid),
        "game_name": data.get("name", f"Steam Game {appid}"),
        "minimum": parse_requirements(req.get("minimum", "")),
        "recommended": parse_requirements(req.get("recommended", "")),
    }


def kirim(payload: dict) -> bool:
    r = requests.post(LARAVEL_URL, json=payload, headers=HEADERS, timeout=30)
    return r.status_code == 201


def main():
    jumlah = int(sys.argv[1]) if len(sys.argv) > 1 else 25
    print(f"Mengambil {jumlah} game terpopuler dari Steam Charts...\n")

    appids = ambil_top_appids(jumlah)
    sukses = 0
    for i, appid in enumerate(appids, 1):
        detail = ambil_detail(appid)
        if detail is None:
            print(f"[{i}/{len(appids)}] appid {appid}: dilewati (bukan game / tanpa detail)")
            continue

        ok = kirim(detail)
        status = "OK" if ok else "GAGAL"
        min_c = detail["minimum"]["cpu"][0] if detail["minimum"]["cpu"] else "-"
        print(f"[{i}/{len(appids)}] {detail['game_name'][:40]:40} | RAM min {detail['minimum']['ram_gb']}GB | CPU {min_c[:30]} -> {status}")
        if ok:
            sukses += 1
        time.sleep(1.2)  # sopan ke Steam API

    print(f"\nSelesai. {sukses}/{len(appids)} game asli Steam tersimpan ke database production.")


if __name__ == "__main__":
    main()

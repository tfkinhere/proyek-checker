"""
Importer katalog dari Steam ASLI (bukan data lokal/buatan).

Alur:
  1. Ambil daftar game TERPOPULER dari Steam Charts (GetMostPlayedGames) -> terurut by peak players.
  2. Untuk tiap appid, ambil detail resmi via store appdetails (nama, tipe, pc_requirements).
  3. Parse HTML pc_requirements menjadi os/cpu/gpu/ram_gb/storage_gb.
  4. Kirim ke endpoint Laravel /api/games/scrape-v2 (updateOrCreate by steam_app_id).

Parser & pembacaan token dipakai ulang dari backfill_specs.py supaya konsisten
(termasuk fallback format non-<li> dan dukungan desimal GB).

Pakai: python import_top_steam.py [jumlah]
  contoh: python import_top_steam.py 100   (default 25)
"""

import sys
import time
import requests

from backfill_specs import parse_requirements, _baca_token

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
    headers = dict(HEADERS)
    token = _baca_token()
    if token:
        headers["X-Scraper-Token"] = token
    payload["spec_source"] = "steam"  # Tandai sumber data spec
    r = requests.post(LARAVEL_URL, json=payload, headers=headers, timeout=30)
    return r.status_code == 201


def main():
    jumlah = int(sys.argv[1]) if len(sys.argv) > 1 else 25
    print(f"Mengambil {jumlah} game terpopuler dari Steam Charts...\n")

    appids = ambil_top_appids(jumlah)
    sukses = 0
    dilewati = 0
    for i, appid in enumerate(appids, 1):
        detail = ambil_detail(appid)
        if detail is None:
            print(f"[{i}/{len(appids)}] appid {appid}: dilewati (bukan game / tanpa detail)")
            dilewati += 1
            continue

        ok = kirim(detail)
        status = "OK" if ok else "GAGAL"
        min_c = detail["minimum"]["cpu"][0] if detail["minimum"]["cpu"] else "-"
        print(f"[{i}/{len(appids)}] {detail['game_name'][:40]:40} | RAM min {detail['minimum']['ram_gb']}GB | CPU {min_c[:30]} -> {status}")
        if ok:
            sukses += 1
        else:
            dilewati += 1
        time.sleep(1.2)  # sopan ke Steam API

    print(f"\nSelesai. {sukses}/{len(appids)} game tersimpan, {dilewati} dilewati.")


if __name__ == "__main__":
    main()

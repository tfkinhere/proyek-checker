@echo off
REM ================================================================
REM AUTO-SCRAPER: Ambil 100 game berikutnya yang spec-nya kosong
REM Setiap klik = 100 game baru (auto-skip yang sudah terisi)
REM ================================================================

cd /d "%~dp0"

REM --- Pastikan file token lokal ada (scraper_token.txt) ---
REM Token TIDAK ditaruh di file ini (file ini ada di repo publik).
REM Cukup buat file scraper_token.txt di folder yang sama berisi nilai
REM SCRAPER_TOKEN dari Azure Portal > game-checker > Environment variables.
REM Nanti dibaca otomatis oleh backfill_specs.py.
if not exist "scraper_token.txt" (
    echo.
    echo [PERINGATAN] File scraper_token.txt tidak ditemukan!
    echo.
    echo Cara: buat file scraper-python\scraper_token.txt lalu isi dengan
    echo nilai SCRAPER_TOKEN dari Azure (tanpa spasi / baris baru).
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo  GAME SPEC AUTO-SCRAPER
echo ========================================
echo.
echo Mengambil 100 game berikutnya dari Steam...
echo (Game yang sudah terisi akan di-skip otomatis)
echo.

python backfill_specs.py 100

echo.
echo ========================================
echo  SELESAI!
echo ========================================
echo.
echo Tunggu 10-15 menit agar tidak kena rate-limit Steam,
echo lalu klik lagi file ini untuk 100 game berikutnya.
echo.
pause

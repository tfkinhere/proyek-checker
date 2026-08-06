@echo off
REM ================================================================
REM AUTO-SCRAPER: Ambil 100 game berikutnya yang spec-nya kosong
REM Setiap klik = 100 game baru (auto-skip yang sudah terisi)
REM ================================================================

cd /d "%~dp0"

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

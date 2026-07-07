import asyncio
import sys
from playwright.async_api import async_playwright

async def main():
    # 1. Validasi input parameter dari terminal (App ID wajib diisi)
    if len(sys.argv) < 2:
        print("Eror: Masukkan App ID game setelah nama file!")
        print("Contoh penggunaan: python scraper.py 271590")
        return

    # Mengambil App ID dari parameter pertama terminal
    app_id = sys.argv[1]
    url = f"https://store.steampowered.com/app/{app_id}/"

    async with async_playwright() as p:
        # 2. Inisiasi browser Chromium di latar belakang
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        
        # 3. Menyuntikkan Cookie Verifikasi Umur agar tidak dihadang Age Gate Steam
        await context.add_cookies([
            {
                "name": "wants_mature_content",
                "value": "1",
                "domain": "store.steampowered.com",
                "path": "/"
            },
            {
                "name": "birthtime",
                "value": "283996801",  # Mengatur timestamp tahun kelahiran agar terbaca dewasa
                "domain": "store.steampowered.com",
                "path": "/"
            }
        ])
        
        # Membuka halaman baru di dalam context browser yang sudah diberi cookie
        page = await context.new_page()

        print(f"Robot meluncur ke Steam URL: {url} ...")
        
        try:
            # 4. Robot terbang menuju URL target
            await page.goto(url)

            # 5. Menunggu sampai elemen spesifikasi sistem Windows muncul (Timeout maks 5 detik)
            await page.wait_for_selector('.game_area_sys_req[data-os="win"]', timeout=5000)

            # 6. Mengekstrak teks mentah spesifikasi PC versi Windows
            sys_req_text = await page.locator('.game_area_sys_req[data-os="win"]').inner_text()

            print("\n=== DATA MENTAH YANG BERHASIL DITANGKAP: ===\n")
            print(sys_req_text)
            print("\n============================================\n")

        except Exception as e:
            print(f"\nGagal mengambil data: Elemen spesifikasi tidak ditemukan atau mengalami timeout. (ID: {app_id})")
            print("Kemungkinan penyebab:")
            print("1. App ID yang dimasukkan salah.")
            print("2. Halaman game tersebut memang tidak memiliki informasi spesifikasi sistem PC di Steam.")

        finally:
            # 7. Pastikan browser selalu ditutup untuk menghemat RAM
            await browser.close()

# Mengeksekusi fungsi utama asynchronous
asyncio.run(main())
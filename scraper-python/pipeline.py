import asyncio
import sys
import os
import requests  # <-- Tambahan library untuk kirim HTTP Request
from dotenv import load_dotenv
from playwright.async_api import async_playwright
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from typing import List, Optional

# 1. Load API Key dari file .env
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("Eror: GEMINI_API_KEY tidak ditemukan di file .env!")
    sys.exit(1)

# 2. Strukturkan Format JSON Target Menggunakan Pydantic
class SpecDetail(BaseModel):
    os: Optional[str] = Field(default=None, description="Versi OS Windows, contoh: Windows 10 64-bit")
    cpu: List[str] = Field(default=[], description="Daftar nama processor yang didukung")
    ram_gb: Optional[int] = Field(default=None, description="Kapasitas RAM dalam angka GB")
    gpu: List[str] = Field(default=[], description="Daftar nama kartu grafis yang didukung")
    storage_gb: Optional[int] = Field(default=None, description="Kapasitas penyimpanan dalam angka GB")

class GameRequirementSchema(BaseModel):
    minimum: SpecDetail
    recommended: SpecDetail

# 3. Fungsi Komunikasi dengan Gemini AI
def bersihkan_dengan_ai(raw_text: str) -> GameRequirementSchema:
    print("Mengirim data mentah ke Gemini AI untuk distrukturkan...")
    client = genai.Client(api_key=api_key)
    
    prompt = f"Ekstrak dan rapikan data spesifikasi sistem PC versi Windows dari teks mentah berikut ke dalam format JSON sesuai skema pydantic:\n\n{raw_text}"
    
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=GameRequirementSchema,
            temperature=0.1
        ),
    )
    return GameRequirementSchema.model_validate_json(response.text)

# 4. Fungsi Mengirim Data JSON ke API Laravel
def kirim_ke_laravel(data_dict: dict, app_id: str):
    url_laravel = "http://127.0.0.1:8000/api/games/scrape-v2"
    print(f"Mengirim data JSON ke API Laravel: {url_laravel} ...")
    
    # Tambahkan nama game bayangan/dummy berdasarkan App ID untuk identifikasi di DB
    data_dict['game_name'] = f"Steam Game ID {app_id}"
    
    try:
        response = requests.post(url_laravel, json=data_dict)
        
        if response.status_code == 201:
            print("\n=============================================")
            print("🎉 KONEKSI SUKSES: Data berhasil masuk MySQL!")
            print("Respon Laravel:", response.json()['message'])
            print("=============================================\n")
        else:
            print(f"\n❌ Laravel menolak data (Status: {response.status_code})")
            print("Pesan Eror:", response.text)
            
    except requests.exceptions.ConnectionError:
        print("\n❌ GAGAL KONEKSI: Pastikan 'php artisan serve' di Laravel sudah dinyalakan!")

# 5. Fungsi Utama Alur Kerja Scraper + AI + Laravel
async def main():
    if len(sys.argv) < 2:
        print("Eror: Masukkan App ID game setelah nama file!")
        print("Contoh penggunaan: python pipeline.py 271590")
        return

    app_id = sys.argv[1]
    url = f"https://store.steampowered.com/app/{app_id}/"

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        
        await context.add_cookies([
            {"name": "wants_mature_content", "value": "1", "domain": "store.steampowered.com", "path": "/"},
            {"name": "birthtime", "value": "283996801", "domain": "store.steampowered.com", "path": "/"}
        ])
        
        page = await context.new_page()
        print(f"Robot meluncur ke Steam URL: {url} ...")
        
        try:
            await page.goto(url)
            await page.wait_for_selector('.game_area_sys_req[data-os="win"]', timeout=5000)
            
            raw_sys_req = await page.locator('.game_area_sys_req[data-os="win"]').inner_text()
            print("Sukses mengambil data mentah dari Steam.")
            
            # Oper ke AI dan ubah jadi objek Python Dictionary
            objek_ai = bersihkan_dengan_ai(raw_sys_req)
            data_json = objek_ai.model_dump()
            
            # Tembak langsung ke backend Laravel!
            kirim_ke_laravel(data_json, app_id)

        except Exception as e:
            print(f"\nGagal menjalankan pipeline: {str(e)}")

        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(main())
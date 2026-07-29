# Konfigurasi Steam Login (tahap 1)

## 1. Firebase Admin untuk Laravel

Unduh _service account JSON_ dari Firebase Console untuk proyek yang sama dengan aplikasi Flutter. Simpan file tersebut di lokasi aman yang tidak masuk Git, lalu isi `.env`:

```env
FIREBASE_CREDENTIALS=C:/lokasi-aman/firebase-service-account.json
```

Laravel sekarang memverifikasi Bearer token Firebase dan membuat/memperbarui user berdasarkan `firebase_uid`. Tidak ada lagi user dummy atau penggunaan `User::first()`.

## 2. URL callback Steam yang publik

Steam OpenID tidak dapat mengembalikan hasil ke `localhost` atau IP LAN. Saat pengembangan, buat tunnel HTTPS yang mengarah ke Laravel lokal; saat production gunakan domain API. Isi URL HTTPS tersebut tanpa garis miring terakhir:

Contoh tunnel sementara:

- Cloudflare Tunnel: `cloudflared tunnel --url http://127.0.0.1:8000`
- ngrok: `ngrok http 8000`

```env
APP_URL=https://api.contoh.com
STEAM_PUBLIC_URL=https://api.contoh.com
```

URL callback yang dipakai sistem adalah:

```text
https://api.contoh.com/api/steam/callback
```

## 3. Database dan cache

Jalankan migrasi setelah memperbarui kode:

```bash
php artisan migrate
```

Kolom `users.steam_id` akan menyimpan SteamID64 yang diterima dan diverifikasi dari Steam. Tautan login bersifat satu kali dan berlaku 10 menit; status sementara disimpan melalui cache Laravel.

## 4. Uji alur

1. Login ke aplikasi dengan Google.
2. Tekan **Connect Steam** pada Profil.
3. Selesaikan login di halaman Steam resmi yang terbuka di browser.
4. Kembali ke aplikasi; koneksi terdeteksi lalu wishlist disinkronkan.

Wishlist Steam harus Public agar Steam dapat mengembalikan daftar game. Jika profil atau wishlist masih privat, backend akan menolak sinkronisasi dengan pesan yang jelas. Memutus koneksi Steam tidak menghapus Saved Content yang sudah ada.

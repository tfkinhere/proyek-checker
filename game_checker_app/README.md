# Game Checker App

## Release Build Untuk Tahap 5

Saat build production, pastikan URL API produksi disuntikkan lewat `--dart-define`.

Contoh untuk Android:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.namaaplikasi.com/api
```

Contoh untuk web:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.namaaplikasi.com/api
```

Jika `API_BASE_URL` tidak diisi saat release, aplikasi akan berhenti dengan error yang jelas agar tidak memakai IP lokal tanpa sengaja.# game_checker_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

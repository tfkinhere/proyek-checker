import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Judul Aplikasi
              Text(
                'Game Checker',
                style: GoogleFonts.figtree(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Teks Sambutan / Deskripsi
              Text(
                'Masuk untuk mulai sinkronisasi spesifikasi HP dan wishlist game-mu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 60),

              // Tombol Login Google
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final AuthService authService = AuthService();

                    // 1. Tunggu proses login Google selesai
                    final userCredential = await authService.signInWithGoogle();

                    // 2. Kita HAPUS perintah Navigator.pushReplacement di sini!
                    // Begitu userCredential berhasil didapat, AuthGate di main.dart
                    // akan mendeteksinya dalam hitungan milidetik dan otomatis
                    // memindahkan layar ke MainNavigationPage (yang ada bottom nav-nya).
                    if (userCredential != null) {
                      print(
                        "Login Berhasil! Selamat datang, ${userCredential.user?.displayName}",
                      );
                    } else {
                      print("Login dibatalkan atau gagal.");
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.g_mobiledata,
                        size: 36,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Login with Google',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

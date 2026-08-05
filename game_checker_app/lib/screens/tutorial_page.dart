import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CARA PENGGUNAAN',
          style: GoogleFonts.figtree(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Selamat Datang di Game Checker!',
            style: GoogleFonts.figtree(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ikuti 4 langkah mudah di bawah ini untuk mulai mengecek apakah PC/Laptop kamu kuat menjalankan game impianmu.',
            style: GoogleFonts.figtree(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Langkah 1
          _buildStepCard(
            stepNumber: '1',
            title: 'Atur Spesifikasi PC/Laptop Kamu',
            description:
                'Masuk ke menu Profil > Change Specification. Masukkan detail CPU, GPU, RAM, dan sisa Storage PC/Laptop-mu saat ini. Data ini adalah kunci dari keakuratan analisa aplikasi.',
            icon: Icons.memory_outlined,
            iconColor: const Color(0xFF4EE2C0),
          ),
          const SizedBox(height: 16),

          // Langkah 2
          _buildStepCard(
            stepNumber: '2',
            title: 'Jelajahi Katalog Game',
            description:
                'Buka menu Katalog untuk menelusuri daftar game. Gunakan kolom pencarian untuk mencari judul tertentu langsung dari Steam.',
            icon: Icons.sports_esports_outlined,
            iconColor: Colors.blueAccent,
          ),
          const SizedBox(height: 16),

          // Langkah 3
          _buildStepCard(
            stepNumber: '3',
            title: 'Simpan Game Favoritmu',
            description:
                'Pada halaman Detail game, klik "Simpan" untuk menandai game. Semua game yang kamu simpan akan muncul di menu Profil > "Saved Content".',
            icon: Icons.bookmark_border_rounded,
            iconColor: Colors.amberAccent,
          ),
          const SizedBox(height: 16),

          // Langkah 4
          _buildStepCard(
            stepNumber: '4',
            title: 'Cek Kelayakan & Mainkan!',
            description:
                'Klik tombol "Cek Kelayakan PC/Laptop Saya" pada game yang kamu inginkan. Aplikasi akan langsung membandingkan spesifikasi PC/Laptop-mu dengan kebutuhan game tersebut secara detail.',
            icon: Icons.analytics_outlined,
            iconColor: Colors.greenAccent,
          ),

          const SizedBox(height: 40),

          // Tombol Selesai
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Saya Mengerti, Ayo Mulai!',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Langkah $stepNumber',
                      style: GoogleFonts.figtree(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

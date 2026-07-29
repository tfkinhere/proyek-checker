import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'result_page.dart';

class PastiLancarPage extends StatelessWidget {
  final List<dynamic> playableGames;
  final Future<void> Function() onRefresh;

  const PastiLancarPage({
    super.key,
    required this.playableGames,
    required this.onRefresh,
  });

  void _navigateToResult(BuildContext context, dynamic game) {
    final adapted = {
      'id': game['id'],
      'title': game['title'],
      'app_id': game['steam_app_id'],
      'status': game['status'],
      'status_key': game['status_key'],
      'reason': game['reason'],
      'min_ram': game['min_specs']?['ram'] ?? 0,
      'min_storage': game['min_specs']?['storage'] ?? 0,
      'rec_ram': game['rec_specs']?['ram'] ?? 0,
      'rec_storage': game['rec_specs']?['storage'] ?? 0,
      'min_os': game['min_os'] ?? '-',
      'min_cpu': game['min_cpu'] ?? '-',
      'min_gpu': game['min_gpu'] ?? '-',
      'rec_os': game['rec_os'] ?? '-',
      'rec_cpu': game['rec_cpu'] ?? '-',
      'rec_gpu': game['rec_gpu'] ?? '-',
    };
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultPage(gameData: adapted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'GAME PASTI LANCAR',
          style: GoogleFonts.figtree(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.bottomNav,
        onRefresh: onRefresh,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar game yang 100% kompatibel dan dipastikan berjalan mulus di spesifikasi PC/Laptop-mu saat ini.',
                  style: GoogleFonts.figtree(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildGridGames(playableGames),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridGames(List<dynamic> games) {
    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Text(
            'Tidak ditemukan game yang sesuai.',
            style: GoogleFonts.figtree(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    final filteredGames = games
        .where((game) => (game['status_key'] ?? 'playable') == 'perfect')
        .toList();

    if (filteredGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Text(
            'Tidak ada game dengan status Pasti Lancar saat ini.',
            style: GoogleFonts.figtree(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredGames.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final game = filteredGames[index];
        String sizeText = 'Size tidak tersedia';
        final minSpecs = game['min_specs'];
        if (minSpecs != null &&
            minSpecs is Map &&
            minSpecs['storage'] != null) {
          sizeText = "${minSpecs['storage']} GB";
        }

        // ✅ PERUBAHAN: dibungkus GestureDetector
        return GestureDetector(
          onTap: () => _navigateToResult(context, game),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bottomNav,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      game['banner_url'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1E2336),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['title'],
                        style: GoogleFonts.figtree(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          game['status']?.toString() ?? 'Pasti Lancar',
                          style: GoogleFonts.figtree(
                            color: AppColors.primaryAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sizeText,
                        style: GoogleFonts.figtree(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

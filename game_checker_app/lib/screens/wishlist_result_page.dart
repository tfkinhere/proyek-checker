import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'result_page.dart';

class WishlistResultPage extends StatefulWidget {
  final List<dynamic> wishlistGames;
  final String mode;

  const WishlistResultPage({
    super.key,
    required this.wishlistGames,
    this.mode = 'Sandbox',
  });

  @override
  State<WishlistResultPage> createState() => _WishlistResultPageState();
}

class _WishlistResultPageState extends State<WishlistResultPage> {
  late List<dynamic> _games;
  final Set<String> _removingGameIds = {};

  bool get _isSavedContent => widget.mode == 'Saved';

  @override
  void initState() {
    super.initState();
    _games = List<dynamic>.from(widget.wishlistGames);
  }

  Map<String, dynamic> _prepareGameDataForResult(Map<String, dynamic> game) {
    final minSpecs = game['min_specs'] is Map ? game['min_specs'] as Map : {};
    final recSpecs = game['rec_specs'] is Map ? game['rec_specs'] as Map : {};
    return {
      'id': game['id'],
      'title': game['title'] ?? game['name'] ?? 'Unknown Game',
      'app_id': game['app_id'] ?? game['steam_app_id'] ?? '0',
      'min_os': game['min_os'] ?? 'Windows 10 64-bit',
      'min_cpu': game['min_cpu'] ?? 'Intel Core i5-6600K / AMD Ryzen 5 1600',
      'min_ram': game['min_ram'] ?? minSpecs['ram'] ?? 8,
      'min_gpu':
          game['min_gpu'] ?? 'NVIDIA GeForce GTX 1060 3GB / AMD Radeon RX 580',
      'min_storage': game['min_storage'] ?? minSpecs['storage'] ?? 70,
      'rec_os': game['rec_os'] ?? 'Windows 11 64-bit',
      'rec_cpu': game['rec_cpu'] ?? 'Intel Core i7-8700K / AMD Ryzen 5 3600',
      'rec_ram': game['rec_ram'] ?? recSpecs['ram'] ?? 16,
      'rec_gpu':
          game['rec_gpu'] ?? 'NVIDIA GeForce RTX 3060 / AMD Radeon RX 6600 XT',
      'rec_storage': game['rec_storage'] ?? recSpecs['storage'] ?? 70,
    };
  }

  Future<void> _removeSavedGame(Map<String, dynamic> game) async {
    final gameId = game['id'];
    if (gameId == null) return;
    final id = gameId.toString();
    if (_removingGameIds.contains(id)) return;
    setState(() => _removingGameIds.add(id));
    final success = await ApiService.removeFromWishlist(gameId);
    if (!mounted) return;
    setState(() {
      _removingGameIds.remove(id);
      if (success) _games.removeWhere((item) => item['id']?.toString() == id);
    });
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus game.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSavedContent ? 'SAVED CONTENT' : 'WISHLIST STEAM SAYA',
              style: GoogleFonts.figtree(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Total: ${_games.length} Game • Mode: ${widget.mode}',
              style: GoogleFonts.figtree(
                fontSize: 12,
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: _games.isEmpty
          ? Center(
              child: Text(
                'Tidak ada game tersimpan.',
                style: GoogleFonts.figtree(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = Map<String, dynamic>.from(_games[index] as Map);
                final name = (game['title'] ?? game['name'] ?? 'Unknown Game')
                    .toString();
                final bannerUrl = (game['banner_url'] ?? '').toString();
                final status = (game['status_kelayakan'] ?? 'Siap Dicek')
                    .toString();
                final gameId = game['id']?.toString() ?? '';
                final removing = _removingGameIds.contains(gameId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.bottomNav,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bannerUrl.isNotEmpty)
                        Stack(
                          children: [
                            Image.network(
                              bannerUrl,
                              height: 145,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _statusBadge(status),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.figtree(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                if (_isSavedContent)
                                  IconButton(
                                    tooltip: 'Hapus dari Saved Content',
                                    onPressed: gameId.isEmpty || removing
                                        ? null
                                        : () => _removeSavedGame(game),
                                    icon: removing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.bookmark_remove_outlined,
                                            color: Colors.redAccent,
                                          ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Steam App ID: ${game['app_id'] ?? game['steam_app_id'] ?? '-'}',
                              style: GoogleFonts.figtree(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResultPage(
                                      gameData: _prepareGameDataForResult(game),
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.memory, size: 18),
                                label: Text(
                                  'Cek Kelayakan PC/Laptop Saya',
                                  style: GoogleFonts.figtree(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 145,
    color: const Color(0xFF171A21),
    child: const Center(
      child: Icon(Icons.videogame_asset, color: Colors.white38, size: 48),
    ),
  );

  Widget _statusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blueAccent),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.analytics_outlined,
          color: Colors.blueAccent,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          status,
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

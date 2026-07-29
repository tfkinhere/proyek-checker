import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'result_page.dart';

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> allGames = [];
  List<dynamic> filteredGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllGames();
  }

  Future<void> _loadAllGames() async {
    try {
      final games = await ApiService.fetchAllGames();
      if (mounted) {
        setState(() {
          allGames = games;
          filteredGames = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToResult(BuildContext context, dynamic game) {
    final adapted = {
      'id': game['id'], // ✅ TAMBAH INI
      'title': game['title'],
      'app_id': game['steam_app_id'],
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterGames(String query) {
    if (query.isEmpty) {
      setState(() => filteredGames = allGames);
    } else {
      setState(() {
        filteredGames = allGames
            .where(
              (game) => game['title'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'KATALOG GAME',
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _filterGames,
                style: GoogleFonts.figtree(fontSize: 15, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari nama game (contoh: Cyberpunk)...',
                  hintStyle: GoogleFonts.figtree(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppColors.bottomNav,
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primaryAccent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    )
                  : _buildGridGames(filteredGames),
            ],
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final game = games[index];
        String sizeText = 'Size tidak tersedia';
        final minSpecs = game['min_specs'];
        if (minSpecs != null &&
            minSpecs is Map &&
            minSpecs['storage'] != null) {
          sizeText = "${minSpecs['storage']} GB";
        }

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
                      game['banner_url'] ?? '',
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
                        game['title'] ?? '-',
                        style: GoogleFonts.figtree(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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

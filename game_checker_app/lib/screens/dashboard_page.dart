import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'result_page.dart';

class DashboardPage extends StatefulWidget {
  final List<dynamic> playableGames;
  final List<dynamic> trendingGames;
  final Map<String, dynamic>? activeSpecs;
  final bool isDataLoading;
  final Future<void> Function() onRefresh;
  final void Function(int) onTabChange;

  const DashboardPage({
    super.key,
    required this.playableGames,
    required this.trendingGames,
    required this.activeSpecs,
    required this.isDataLoading,
    required this.onRefresh,
    required this.onTabChange,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _appIdController = TextEditingController();
  bool _isLoading = false;
  int _trendingIndex = 0;
  bool _isHardwareExpanded = false;

  @override
  void dispose() {
    _appIdController.dispose();
    super.dispose();
  }

  // Fungsi Cek Kelayakan via Steam
  Future<void> _fetchGameData(String appId) async {
    setState(() => _isLoading = true);
    String url = "${ApiService.baseUrl}/games/check";

    try {
      Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      Response response = await dio.post(
        url,
        data: {'app_id': appId},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultPage(gameData: response.data['data'] ?? response.data),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      String pesanError = 'Gagal terhubung ke server.';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          pesanError =
              'Koneksi habis waktu (Timeout). Pastikan server PHP aktif.';
        } else if (e.response != null) {
          final dataLengkap = e.response?.data;
          if (dataLengkap is Map && dataLengkap.containsKey('message')) {
            pesanError = dataLengkap['message'];
          } else {
            pesanError =
                'Terjadi kesalahan server (Status: ${e.response?.statusCode})';
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pesanError,
                    style: GoogleFonts.figtree(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.bottomNav,
        onRefresh: widget.onRefresh,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildTrendingSection(),
                const SizedBox(height: 24),
                _buildWajibCobaSection(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPastiLancarSection(),
                      const SizedBox(height: 36),
                      _buildHardwareSpecsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TRENDING SECTION
  // ==========================================
  Widget _buildTrendingSection() {
    final games = widget.trendingGames.isNotEmpty
        ? widget.trendingGames
        : widget.playableGames;
    final game = games.isNotEmpty ? games[_trendingIndex] : null;

    final String title = game != null ? game['title'] : '[Nama Game Trending]';
    final String bannerUrl = game != null
        ? game['banner_url']
        : 'https://cdn.akamai.steamstatic.com/steam/apps/1091500/header.jpg';

    String size = 'Size tidak tersedia';
    if (game != null) {
      final minSpecs = game['min_specs'];
      if (minSpecs != null && minSpecs is Map && minSpecs['storage'] != null) {
        size = "${minSpecs['storage']} GB";
      }
    }

    return Container(
      width: double.infinity,
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Banner dengan animasi
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                    Tween<Offset>(
                      begin: const Offset(0.15, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                key: ValueKey<int>(_trendingIndex),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E2336),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    AppColors.background,
                  ],
                  stops: const [0.3, 0.85, 1.0],
                ),
              ),
            ),
          ),

          // Teks dengan animasi
          Positioned(
            left: 20,
            bottom: 20,
            right: 70,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                final offsetAnimation =
                    Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  key: ValueKey<int>(_trendingIndex),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      games.isNotEmpty
                          ? 'Trending ${_trendingIndex + 1}/${games.length}'
                          : 'Trending',
                      style: GoogleFonts.figtree(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.figtree(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      size,
                      style: GoogleFonts.figtree(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tombol >
          Positioned(
            right: 16,
            bottom: 20,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 18,
                ),
                onPressed: () {
                  if (games.isNotEmpty) {
                    setState(() {
                      _trendingIndex = (_trendingIndex + 1) % games.length;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WAJIB COBA SECTION
  // ==========================================
  Widget _buildWajibCobaSection() {
    final List<dynamic> games = widget.playableGames.isNotEmpty
        ? widget.playableGames
        : [
            {
              'title': 'Red Dead Redemption 2',
              'banner_url':
                  'https://cdn.akamai.steamstatic.com/steam/apps/1174180/header.jpg',
            },
            {
              'title': 'Grand Theft Auto V',
              'banner_url':
                  'https://cdn.akamai.steamstatic.com/steam/apps/271590/header.jpg',
            },
            {
              'title': 'Elden Ring',
              'banner_url':
                  'https://cdn.akamai.steamstatic.com/steam/apps/1245620/header.jpg',
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Game Wajib Coba',
            style: GoogleFonts.figtree(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final String badgeText = index % 2 == 0 ? 'Details' : 'Waktu';

              String sizeText = 'Size tidak tersedia';
              final minSpecs = game['min_specs'];
              if (minSpecs != null &&
                  minSpecs is Map &&
                  minSpecs['storage'] != null) {
                sizeText = "${minSpecs['storage']} GB";
              }

              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.bottomNav,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          game['banner_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1E2336),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8F71FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.figtree(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game['title'],
                            style: GoogleFonts.figtree(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PASTI LANCAR SECTION (preview 6 game)
  // ==========================================
  Widget _buildPastiLancarSection() {
    final previewGames = widget.playableGames.length > 6
        ? widget.playableGames.sublist(0, 6)
        : widget.playableGames;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Game Pasti Lancar',
              style: GoogleFonts.figtree(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () => widget.onTabChange(1), // ✅ pindah ke Tab 1
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.figtree(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGridGames(previewGames),
      ],
    );
  }

  // ==========================================
  // HARDWARE SPECS SECTION
  // ==========================================
  Widget _buildHardwareSpecsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spesifikasi Hardware',
                style: GoogleFonts.figtree(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => _isHardwareExpanded = !_isHardwareExpanded,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isHardwareExpanded ? 'Hide' : 'Show',
                            style: GoogleFonts.figtree(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isHardwareExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onRefresh,
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isDataLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isHardwareExpanded
                  ? Column(
                      children: [
                        _buildPillSpecTile(
                          Icons.developer_board,
                          'CPU',
                          widget.activeSpecs?['cpu'] ?? '[CPU USER]',
                        ),
                        _buildPillSpecTile(
                          Icons.videocam_rounded,
                          'GPU',
                          widget.activeSpecs?['gpu'] ?? '[GPU USER]',
                        ),
                        _buildPillSpecTile(
                          Icons.memory,
                          'RAM',
                          widget.activeSpecs != null
                              ? "${widget.activeSpecs!['ram']} GB"
                              : '[RAM USER]',
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildPillSpecTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // GRID GAMES (dipakai di beberapa section)
  // ==========================================
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

        // ✅ PERUBAHAN: Container dibungkus GestureDetector
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/wishlist_refresh_notifier.dart';

class ResultPage extends StatefulWidget {
  final dynamic gameData;
  const ResultPage({super.key, required this.gameData});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  double _userRam = 8.0;
  double _userStorage = 256.0;
  String _userOs = 'Windows 11 64-bit';
  String _userCpu = 'Intel Core i5 / AMD Ryzen 5';
  String _userGpu = 'NVIDIA GTX 1650 / AMD RX 570';
  bool? _serverCompatibility;
  String? _serverStatusLabel;
  String? _serverStatusKey;
  String? _serverReason;
  bool _isSaved = false;
  bool _isWishlistLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPCSpecs();
    _checkIfSaved(); // ✅ TAMBAH INI
  }

  Future<void> _checkIfSaved() async {
    final gameId = widget.gameData['id'];
    if (gameId == null) return;
    final savedGames = await ApiService.fetchSavedGames();
    if (mounted) {
      setState(() {
        _isSaved = savedGames.any(
          (g) => g['id']?.toString() == gameId.toString(),
        );
      });
    }
  }

  Future<void> _loadUserPCSpecs() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic>? serverSpecs;
    bool? serverCompatibility;
    String? serverStatusLabel;
    String? serverStatusKey;
    String? serverReason;

    try {
      final homeData = await ApiService.fetchHomeData();
      serverSpecs = homeData['user_active_specs'] as Map<String, dynamic>?;
      final gameId = widget.gameData['id']?.toString();
      final playableGames = homeData['playable_games'];
      if (gameId != null && playableGames is List) {
        final matchedGame = playableGames.firstWhere(
          (game) => game is Map && game['id']?.toString() == gameId,
          orElse: () => null,
        );
        if (matchedGame is Map) {
          serverCompatibility = true;
          serverStatusLabel = matchedGame['status']?.toString();
          serverStatusKey = matchedGame['status_key']?.toString();
          serverReason = matchedGame['reason']?.toString();
        } else {
          serverCompatibility = false;
        }
      }
    } catch (_) {
      // Saat offline, tampilan detail tetap memakai data lokal terakhir.
    }

    if (mounted) {
      setState(() {
        _userRam = (serverSpecs?['ram'] ?? prefs.getDouble('user_ram') ?? 8)
            .toDouble();
        _userStorage =
            (serverSpecs?['storage'] ?? prefs.getDouble('user_storage') ?? 256)
                .toDouble();
        _userOs =
            serverSpecs?['os'] ??
            prefs.getString('user_os') ??
            'Windows 11 64-bit';
        _userCpu =
            serverSpecs?['cpu'] ??
            prefs.getString('user_cpu') ??
            'Intel Core i5 / AMD Ryzen 5';
        _userGpu =
            serverSpecs?['gpu'] ??
            prefs.getString('user_gpu') ??
            'NVIDIA GTX 1650 / AMD RX 570';
        _serverCompatibility = serverCompatibility;
        _serverStatusLabel = serverStatusLabel;
        _serverStatusKey = serverStatusKey;
        _serverReason = serverReason;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    if (_isWishlistLoading) return;

    final gameId = widget.gameData['id'];
    if (gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Game ini tidak bisa disimpan.',
            style: GoogleFonts.figtree(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isWishlistLoading = true);

    final wasSaved = _isSaved;
    final success = wasSaved
        ? await ApiService.removeFromWishlist(gameId)
        : await ApiService.addToWishlist(gameId);

    if (mounted) {
      setState(() {
        _isWishlistLoading = false;
        if (success) _isSaved = !wasSaved;
      });

      if (success) {
        WishlistRefreshNotifier.notifyChanged();
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasSaved
                  ? 'Gagal menghapus game dari Saved Content.'
                  : 'Gagal menyimpan game.',
              style: GoogleFonts.figtree(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  bool get _isCompatible {
    if (_serverStatusKey != null) {
      return _serverStatusKey != 'not_compatible';
    }

    double minRam =
        double.tryParse(widget.gameData['min_ram'].toString()) ?? 0.0;
    double minStorage =
        double.tryParse(widget.gameData['min_storage'].toString()) ?? 0.0;
    return _userRam >= minRam && _userStorage >= minStorage;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.gameData;
    final String title = data['title'] ?? 'Detail Game';
    final String appId = data['app_id']?.toString() ?? '0';
    final String bannerUrl =
        'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg';

    final dynamic storageVal = data['min_storage'] ?? 0;
    final String sizeText = '$storageVal GB';

    final String sinopsis =
        data['description'] ??
        'Game ini tersedia di Steam. Cek spesifikasi minimum dan rekomendasi di bawah untuk memastikan PC/Laptop kamu siap.';

    final bool compatible = _serverCompatibility ?? _isCompatible;
    final String statusLabel =
        _serverStatusLabel ??
        widget.gameData['status']?.toString() ??
        (compatible ? 'Bisa Dicoba' : 'Tidak Kompatibel');
    final String statusKey =
        _serverStatusKey ??
        widget.gameData['status_key']?.toString() ??
        (compatible ? 'playable' : 'not_compatible');
    final String reason =
        _serverReason ??
        widget.gameData['reason']?.toString() ??
        'Spesifikasi Anda cukup kuat untuk mencoba permainan ini.';
    final Color statusColor = statusKey == 'perfect'
        ? Colors.greenAccent
        : statusKey == 'playable'
        ? Colors.amberAccent
        : Colors.redAccent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail',
          style: GoogleFonts.figtree(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BANNER ──────────────────────────────
            Image.network(
              bannerUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: const Color(0xFF1E2336),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white38,
                    size: 48,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── JUDUL ────────────────────────────
                  Text(
                    title,
                    style: GoogleFonts.figtree(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── SINOPSIS ─────────────────────────
                  Text(
                    sinopsis,
                    style: GoogleFonts.figtree(
                      fontSize: 13,
                      color: Colors.white54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SIZE + BOOKMARK ───────────────────
                  Text(
                    'Size',
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Chip size
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sizeText,
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol bookmark
                      GestureDetector(
                        onTap: _toggleWishlist,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isSaved
                                ? AppColors.primaryAccent.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isSaved
                                  ? AppColors.primaryAccent
                                  : Colors.white24,
                            ),
                          ),
                          child: _isWishlistLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryAccent,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      color: _isSaved
                                          ? AppColors.primaryAccent
                                          : Colors.white54,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isSaved ? 'Tersimpan' : 'Simpan',
                                      style: GoogleFonts.figtree(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _isSaved
                                            ? AppColors.primaryAccent
                                            : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── STATUS ───────────────────────────
                  Text(
                    'Status',
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        statusLabel,
                        style: GoogleFonts.figtree(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181C27),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.figtree(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SPESIFIKASI ──────────────────────
                  Text(
                    'Spesifikasi',
                    style: GoogleFonts.figtree(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header kolom
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Minimum',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Rekomendasi',
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tabel spesifikasi
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bottomNav,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSpecRow(
                          label: 'CPU',
                          minVal: data['min_cpu'] ?? '-',
                          recVal: data['rec_cpu'] ?? '-',
                        ),
                        _buildDivider(),
                        _buildSpecRow(
                          label: 'GPU',
                          minVal: data['min_gpu'] ?? '-',
                          recVal: data['rec_gpu'] ?? '-',
                        ),
                        _buildDivider(),
                        _buildSpecRow(
                          label: 'RAM',
                          minVal: '${data['min_ram'] ?? '-'} GB',
                          recVal: '${data['rec_ram'] ?? '-'} GB',
                        ),
                        _buildDivider(),
                        _buildSpecRow(
                          label: 'Storage',
                          minVal: '${data['min_storage'] ?? '-'} GB',
                          recVal: '${data['rec_storage'] ?? '-'} GB',
                        ),
                        _buildDivider(),
                        _buildSpecRow(
                          label: 'OS',
                          minVal: data['min_os'] ?? '-',
                          recVal: data['rec_os'] ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── INFO PC USER ─────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181C27),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.computer_rounded,
                          color: AppColors.primaryAccent,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'PC/Laptop Kamu: $_userCpu | ${_userRam.toInt()} GB RAM | Sisa: ${_userStorage.toInt()} GB',
                            style: GoogleFonts.figtree(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow({
    required String label,
    required String minVal,
    required String recVal,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.figtree(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  minVal,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('', style: GoogleFonts.figtree(fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  recVal,
                  style: GoogleFonts.figtree(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
  );
}

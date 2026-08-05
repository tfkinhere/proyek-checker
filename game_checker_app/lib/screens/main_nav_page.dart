import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'pasti_lancar_page.dart';
import 'katalog_page.dart';
import 'profile_page.dart';
import 'change_spec_page.dart';
import '../services/spec_refresh_notifier.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // Data game disimpan di sini agar bisa dibagikan ke semua tab
  List<dynamic> playableGames = [];
  List<dynamic> trendingGames = [];
  Map<String, dynamic>? activeSpecs;
  bool _isDataLoading = true;
  bool _hasPromptedSpec = false;
  late final VoidCallback _specRefreshListener;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh dashboard saat spesifikasi hardware berubah dari halaman
    // mana pun (mis. Profil > Change Specification), tanpa refresh manual.
    _specRefreshListener = () {
      if (mounted) _loadData();
    };
    SpecRefreshNotifier.version.addListener(_specRefreshListener);
    // Setelah frame pertama, cek apakah user sudah punya spesifikasi aktif di
    // server. Kalau belum, ingatkan lewat popup (kasus login pertama kali).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSpecAndPrompt());
  }

  @override
  void dispose() {
    SpecRefreshNotifier.version.removeListener(_specRefreshListener);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);
    try {
      final data = await ApiService.fetchHomeData();
      List<dynamic> fetchedGames = List.from(data['playable_games'] ?? []);
      List<dynamic> fetchedTrendingGames = List.from(
        data['trending_games'] ?? [],
      );
      setState(() {
        playableGames = fetchedGames;
        trendingGames = fetchedTrendingGames;
        activeSpecs = data['user_active_specs'];
        _isDataLoading = false;
      });
    } catch (e) {
      setState(() => _isDataLoading = false);
    }
  }

  /// Cek spesifikasi aktif di server. Jika user belum pernah mengisi spek,
  /// tampilkan popup pengingat (hanya sekali per sesi aplikasi).
  Future<void> _checkSpecAndPrompt() async {
    if (_hasPromptedSpec) return;
    try {
      final activeSpec = await ApiService.fetchActiveSpec();
      if (!mounted || _hasPromptedSpec) return;
      if (activeSpec == null) {
        _hasPromptedSpec = true;
        _showSpecReminderDialog();
      }
    } catch (_) {
      // Gagal cek (mis. offline) -> jangan ganggu user dengan popup.
    }
  }

  void _showSpecReminderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bottomNav,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.memory_rounded,
                color: AppColors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Lengkapi Spesifikasi',
                style: GoogleFonts.figtree(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tolong masukkan spesifikasi hardware Anda terlebih dahulu di halaman '
          'Profile agar hasil pengecekan kelayakan game menjadi akurat.',
          style: GoogleFonts.figtree(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Nanti Saja',
              style: GoogleFonts.figtree(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Dashboard akan auto-refresh lewat SpecRefreshNotifier begitu
              // spek tersimpan, jadi cukup buka halaman ubah spek.
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangeSpecPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Isi Sekarang',
              style: GoogleFonts.figtree(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kirim data ke masing-masing halaman
    final List<Widget> pages = [
      DashboardPage(
        playableGames: playableGames,
        trendingGames: trendingGames,
        activeSpecs: activeSpecs,
        isDataLoading: _isDataLoading,
        onRefresh: _loadData,
        onTabChange: (index) => setState(() => _selectedIndex = index),
      ),
      PastiLancarPage(playableGames: playableGames, onRefresh: _loadData),
      const KatalogPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151A2D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_filled),
                _buildNavItem(1, Icons.sports_martial_arts),
                _buildNavItem(2, Icons.sports_esports),
                _buildNavItem(3, Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? AppColors.primaryAccent : Colors.white38,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

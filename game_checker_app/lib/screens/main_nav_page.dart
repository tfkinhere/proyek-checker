import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'pasti_lancar_page.dart';
import 'katalog_page.dart';
import 'profile_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
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

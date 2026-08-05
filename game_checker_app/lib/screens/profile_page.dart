import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// image_picker sudah dihapus dari sini karena diurus oleh edit_profile_page
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import 'wishlist_result_page.dart';
import 'edit_profile_page.dart';
import '../utils/glass_snackbar.dart';
import 'change_spec_page.dart';
import 'tutorial_page.dart';
import '../services/api_service.dart';
import '../services/wishlist_refresh_notifier.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  late final VoidCallback _wishlistRefreshListener;

  List<dynamic> _savedGames = [];

  @override
  void initState() {
    super.initState();
    _wishlistRefreshListener = () {
      if (mounted) {
        _loadSavedGames();
      }
    };
    WishlistRefreshNotifier.version.addListener(_wishlistRefreshListener);
    _loadUserData();
    _loadSavedGames();
  }

  @override
  void dispose() {
    WishlistRefreshNotifier.version.removeListener(_wishlistRefreshListener);
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();

    final savedPath = prefs.getString('profile_image_${user.uid}');
    if (savedPath != null && File(savedPath).existsSync()) {
      if (mounted) setState(() => _profileImage = File(savedPath));
    }
  }

  Future<void> _loadSavedGames() async {
    final games = await ApiService.fetchSavedGames();
    if (mounted) {
      setState(() => _savedGames = games);
    }
  }

  Future<void> _openSavedContent() async {
    // Fetch saved games fresh to avoid race condition with async initState
    final freshSavedGames = await ApiService.fetchSavedGames();
    if (!mounted) return;

    if (freshSavedGames.isEmpty) {
      GlassSnackBar.show(
        context,
        'Belum ada game tersimpan. Bookmark game dari halaman Detail!',
        isWarning: true,
      );
      return;
    }

    setState(() => _savedGames = freshSavedGames);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WishlistResultPage(wishlistGames: freshSavedGames, mode: 'Saved'),
      ),
    );
    _loadSavedGames();
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bottomNav,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          '1. Pengumpulan Data: Kami menyimpan identitas akun Google yang telah diverifikasi untuk keperluan Saved Content.\n\n2. Spesifikasi: Data spesifikasi PC/Laptop yang Anda masukkan hanya dipakai untuk mengevaluasi kelayakan game.\n\n3. Keamanan: Login Google dikelola oleh Firebase Authentication.',
          style: GoogleFonts.figtree(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mengerti',
              style: GoogleFonts.figtree(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Mapple';
    final String roleName = 'Player';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/570/header.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40),
                          Text(
                            'Profil',
                            style: GoogleFonts.figtree(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.bottomNav,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 4,
                                ),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: FileImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : const DecorationImage(
                                        image: NetworkImage(
                                          'https://api.dicebear.com/7.x/adventurer/png?seed=Mapple',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4EE2C0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName,
                          style: GoogleFonts.figtree(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleName,
                          style: GoogleFonts.figtree(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT',
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bottomNav,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          Icons.edit_outlined,
                          'Edit Profile',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(
                                onProfileUpdated: () {
                                  _loadUserData();
                                },
                              ),
                            ),
                          ),
                        ),
                        _buildDivider(),

                        _buildMenuItem(
                          Icons.bookmark_border_rounded,
                          'Saved content',
                          onTap: _openSavedContent,
                        ),
                        _buildDivider(),

                        _buildMenuItem(
                          Icons.memory_outlined,
                          'Change Specification (PC/Laptop)',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangeSpecPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'OTHER SETTING',
                    style: GoogleFonts.figtree(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bottomNav,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          Icons.menu_book_rounded,
                          'Tutorial Cara Menggunakan Aplikasi',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorialPage(),
                            ),
                          ),
                        ),
                        _buildDivider(),

                        _buildMenuItem(
                          Icons.privacy_tip_outlined,
                          'Privacy policy',
                          onTap: _showPrivacyPolicyDialog,
                        ),
                        _buildDivider(),

                        _buildMenuItem(
                          Icons.logout_rounded,
                          'Deactivate account / Logout',
                          isDestructive: true,
                          onTap: () async =>
                              await FirebaseAuth.instance.signOut(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.redAccent : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.figtree(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white30,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
  );
}

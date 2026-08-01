import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
// image_picker sudah dihapus dari sini karena diurus oleh edit_profile_page
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isSteamConnected = false;
  bool _isLoadingWishlist = false;
  late final VoidCallback _wishlistRefreshListener;

  List<dynamic> _cachedWishlist = [];
  List<dynamic> _savedGames = [];
  String _cachedMode = 'Sandbox';

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

    try {
      final connected = await ApiService.fetchSteamConnectionStatus();
      if (mounted) setState(() => _isSteamConnected = connected);
    } catch (error) {
      debugPrint('Gagal membaca status Steam: $error');
    }

    final savedWishlistJson = prefs.getString('cached_wishlist_${user.uid}');
    final savedMode = prefs.getString('cached_mode_${user.uid}');
    if (savedWishlistJson != null) {
      try {
        final decodedList = jsonDecode(savedWishlistJson);
        if (mounted) {
          setState(() {
            _cachedWishlist = decodedList;
            _cachedMode = savedMode ?? 'Sandbox';
          });
        }
      } catch (e) {
        debugPrint('Gagal membaca cache wishlist: $e');
      }
    }
  }

  Future<void> _loadSavedGames() async {
    final games = await ApiService.fetchSavedGames();
    if (mounted) {
      setState(() => _savedGames = games);
    }
  }

  Future<void> _connectOrSyncSteam() async {
    if (_isSteamConnected) {
      await _syncSteamWishlist();
      return;
    }

    setState(() => _isLoadingWishlist = true);
    try {
      final link = await ApiService.startSteamLink();
      final authorizationUrl = Uri.parse(link['authorization_url'] as String);
      final linkToken = link['link_token'] as String;
      if (!await launchUrl(
        authorizationUrl,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Browser tidak dapat dibuka.');
      }
      if (!mounted) return;
      GlassSnackBar.show(
        context,
        'Selesaikan login di Steam. Aplikasi akan memeriksa koneksi secara otomatis.',
      );
      await _waitForSteamLink(linkToken);
    } catch (error) {
      if (mounted) {
        GlassSnackBar.show(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingWishlist = false);
    }
  }

  Future<void> _waitForSteamLink(String linkToken) async {
    for (var attempt = 0; attempt < 40 && mounted; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final status = await ApiService.fetchSteamLinkStatus(linkToken);
        if (!mounted) return;
        if (status['connected'] == true) {
          setState(() => _isSteamConnected = true);
          GlassSnackBar.show(context, 'Akun Steam berhasil terhubung.');
          await _syncSteamWishlist();
          return;
        }
      } catch (_) {
        break;
      }
    }
    if (mounted) {
      GlassSnackBar.show(
        context,
        'Koneksi belum selesai. Ketuk Connect Steam lagi untuk mencoba ulang.',
        isWarning: true,
      );
    }
  }

  Future<void> _syncSteamWishlist() async {
    setState(() => _isLoadingWishlist = true);
    try {
      final responseData = await ApiService.syncSteamWishlist();
      final status = responseData['status']?.toString() ?? 'queued';
      final syncToken = responseData['sync_token']?.toString();

      if (status == 'queued') {
        if (syncToken == null || syncToken.isEmpty) {
          throw Exception('Token sinkronisasi wishlist tidak ditemukan.');
        }
        await _waitForSteamWishlistSync(syncToken);
        return;
      }

      if (responseData['data'] is List) {
        final gamesData = responseData['data'] as List<dynamic>;
        final modeInfo = responseData['mode']?.toString() ?? 'Saved';
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'cached_wishlist_${user.uid}',
            jsonEncode(gamesData),
          );
          await prefs.setString('cached_mode_${user.uid}', modeInfo);
        }
        if (!mounted) return;
        setState(() {
          _cachedWishlist = gamesData;
          _cachedMode = modeInfo;
        });
        await _loadSavedGames();
        GlassSnackBar.show(context, 'Wishlist Steam berhasil disinkronkan.');
        _openWishlistPage(gamesData, modeInfo);
        return;
      }

      throw Exception(
        responseData['message']?.toString() ??
            'Respons wishlist dari server tidak valid.',
      );
    } catch (error) {
      if (mounted) {
        GlassSnackBar.show(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingWishlist = false);
    }
  }

  Future<void> _waitForSteamWishlistSync(String syncToken) async {
    for (var attempt = 0; attempt < 20 && mounted; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final status = await ApiService.fetchSteamWishlistSyncStatus(syncToken);
        final syncData = status['data'] is Map<String, dynamic>
            ? status['data'] as Map<String, dynamic>
            : null;
        final syncStatus = syncData?['status']?.toString() ?? '';

        if (syncStatus == 'completed') {
          final refreshedGames = await ApiService.fetchSavedGames();
          if (!mounted) return;
          setState(() {
            _savedGames = refreshedGames;
            _cachedWishlist = refreshedGames;
            _cachedMode = 'Saved';
          });
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'cached_wishlist_${user.uid}',
              jsonEncode(refreshedGames),
            );
            await prefs.setString('cached_mode_${user.uid}', 'Saved');
          }
          GlassSnackBar.show(context, 'Wishlist Steam berhasil disinkronkan.');
          _openWishlistPage(refreshedGames, 'Saved');
          return;
        }

        if (syncStatus == 'failed') {
          throw Exception(
            syncData?['message']?.toString() ??
                'Sinkronisasi wishlist Steam gagal.',
          );
        }
      } catch (error) {
        if (mounted) {
          GlassSnackBar.show(
            context,
            error.toString().replaceFirst('Exception: ', ''),
            isError: true,
          );
        }
        return;
      }
    }

    if (mounted) {
      GlassSnackBar.show(
        context,
        'Sinkronisasi masih berjalan. Coba lagi beberapa saat.',
        isWarning: true,
      );
    }
  }

  // FUNGSI YANG SEBELUMNYA TIDAK SENGAJA TERHAPUS
  void _openWishlistPage(List<dynamic> games, String mode) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WishlistResultPage(wishlistGames: games, mode: mode),
      ),
    );
  }

  Future<void> _openSavedContent() async {
    if (_savedGames.isEmpty) {
      GlassSnackBar.show(
        context,
        'Belum ada game tersimpan. Bookmark game dari halaman Detail!',
        isWarning: true,
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WishlistResultPage(wishlistGames: _savedGames, mode: 'Saved'),
      ),
    );
    _loadSavedGames();
  }

  Future<void> _unlinkSteam() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await ApiService.unlinkSteam();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_wishlist_${user.uid}');
        await prefs.remove('cached_mode_${user.uid}');
      }
      if (!mounted) return;
      setState(() {
        _isSteamConnected = false;
        _cachedWishlist = [];
        _cachedMode = 'Sandbox';
      });
      GlassSnackBar.show(
        context,
        'Koneksi akun Steam diputuskan.',
        isWarning: true,
      );
    } catch (error) {
      if (mounted) {
        GlassSnackBar.show(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  void _showDisconnectSteamDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bottomNav,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Putuskan Steam Wishlist?',
          style: GoogleFonts.figtree(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Koneksi Steam akan dihapus dari akun Anda. Saved Content tidak akan dihapus.',
          style: GoogleFonts.figtree(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: GoogleFonts.figtree(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _unlinkSteam();
            },
            child: Text(
              'Putuskan',
              style: GoogleFonts.figtree(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
          '1. Pengumpulan Data: Kami menyimpan identitas akun Google dan SteamID yang telah diverifikasi untuk keperluan wishlist.\n\n2. Data Steam: Wishlist hanya dapat disinkronkan bila profil dan wishlist Steam bersifat Public.\n\n3. Keamanan: Login Google dikelola Firebase Authentication; login Steam dilakukan di halaman Steam resmi melalui OpenID.',
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
                          Icons.sports_esports_outlined,
                          _isSteamConnected
                              ? 'Steam Wishlist (Connected)'
                              : 'Connect Steam',
                          trailingText: _isSteamConnected
                              ? 'Sync Now'
                              : 'Connect',
                          trailingColor: _isSteamConnected
                              ? const Color(0xFF4EE2C0)
                              : Colors.blueAccent,
                          isLoading: _isLoadingWishlist,
                          onTap: _connectOrSyncSteam,
                          onLongPress: _isSteamConnected ? _unlinkSteam : null,
                        ),
                        if (_isSteamConnected) ...[
                          _buildDivider(),
                          _buildMenuItem(
                            Icons.link_off_rounded,
                            'Putuskan Steam Wishlist',
                            isDestructive: true,
                            onTap: _showDisconnectSteamDialog,
                          ),
                        ],
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
    VoidCallback? onLongPress,
    bool isDestructive = false,
    String? trailingText,
    Color? trailingColor,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blueAccent,
                ),
              )
            else if (trailingText != null) ...[
              Text(
                trailingText,
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trailingColor,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white30,
                size: 14,
              ),
            ] else if (!isDestructive)
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

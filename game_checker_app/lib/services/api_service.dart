import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String _devBaseUrl = 'http://192.168.1.2:8000/api';

  static String get baseUrl => _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const definedBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (definedBaseUrl.isNotEmpty) {
      return definedBaseUrl;
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL wajib diisi saat build release. Gunakan URL API produksi Azure.',
      );
    }

    return _devBaseUrl;
  }

  // Fungsi untuk mengambil data Beranda dari Laravel
  static Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User belum login ke Firebase.');

      final token = await user.getIdToken();
      final response = await http
          .get(
            Uri.parse('$baseUrl/home'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>) {
          return decoded['data'];
        }
        throw Exception('Respons server tidak valid.');
      }

      throw Exception(
        _parseErrorMessage(response.body, 'Gagal memuat data dari server.'),
      );
    } catch (e) {
      print('Error pada fetchHomeData: $e');
      rethrow;
    }
  }

  // 3. TAMBAHAN BARU: Fungsi untuk menyimpan spek permanen ke database Laravel
  static Future<bool> saveUserSpecs({
    required String os,
    required String cpu,
    required String gpu,
    required int ram,
    required int storage,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User belum login ke Firebase.');
      }

      final token = await user.getIdToken();
      final response = await http
          .post(
            Uri.parse('$baseUrl/specs/update'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'os': os,
              'cpu': cpu,
              'gpu': gpu,
              'ram': ram,
              'storage': storage,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      throw Exception(
        _parseErrorMessage(response.body, 'Gagal menyimpan spesifikasi.'),
      );
    } catch (e) {
      print('=== ERROR FATAL saveUserSpecs: $e ===');
      return false;
    }
  }

  static Future<List<dynamic>> fetchAllGames() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/games/all'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      throw Exception('Respons daftar game tidak valid.');
    }

    throw Exception(
      _parseErrorMessage(response.body, 'Gagal mengambil daftar game.'),
    );
  }

  // Tambah game ke wishlist
  static Future<bool> addToWishlist(int gameId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final token = await user.getIdToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/wishlist/add'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'game_id': gameId}),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('=== ERROR addToWishlist: $e');
      return false;
    }
  }

  // Ambil wishlist user dari database
  static Future<List<dynamic>> fetchSavedGames() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      final token = await user.getIdToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/wishlist'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        }
        return [];
      }
      return [];
    } catch (e) {
      print('=== ERROR fetchSavedGames: $e');
      return [];
    }
  }

  static Future<bool> removeFromWishlist(int gameId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final token = await user.getIdToken();

      final response = await http
          .delete(
            Uri.parse('$baseUrl/wishlist/remove'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'game_id': gameId}),
          )
          .timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (e) {
      print('=== ERROR removeFromWishlist: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> startSteamLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login ke Firebase.');
    final token = await user.getIdToken();
    final response = await http
        .post(Uri.parse('$baseUrl/steam/link'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));
    return _decodeObject(response, 'Gagal memulai koneksi Steam.');
  }

  static Future<Map<String, dynamic>> fetchSteamLinkStatus(
    String linkToken,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login ke Firebase.');
    final token = await user.getIdToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/steam/link/$linkToken'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeObject(response, 'Status koneksi Steam tidak dapat dibaca.');
  }

  static Future<bool> fetchSteamConnectionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdToken();
    final response = await http
        .get(Uri.parse('$baseUrl/steam/status'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));
    final data = _decodeObject(response, 'Status Steam tidak dapat dibaca.');
    return data['connected'] == true;
  }

  static Future<void> unlinkSteam() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login ke Firebase.');
    final token = await user.getIdToken();
    final response = await http
        .post(Uri.parse('$baseUrl/steam/unlink'), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));
    _decodeObject(response, 'Gagal memutuskan koneksi Steam.');
  }

  static Future<Map<String, dynamic>> syncSteamWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login ke Firebase.');
    final token = await user.getIdToken();
    final response = await http
        .post(
          Uri.parse('$baseUrl/steam/wishlist'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 30));
    return _decodeObject(response, 'Wishlist Steam tidak dapat disinkronkan.');
  }

  static Future<Map<String, dynamic>> fetchSteamWishlistSyncStatus(
    String syncToken,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User belum login ke Firebase.');
    final token = await user.getIdToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/steam/wishlist/$syncToken'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeObject(
      response,
      'Status sinkronisasi wishlist Steam tidak dapat dibaca.',
    );
  }

  static Map<String, String> _authHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static String _parseErrorMessage(String body, String fallbackMessage) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}

    return fallbackMessage;
  }

  static Map<String, dynamic> _decodeObject(
    http.Response response,
    String fallbackMessage,
  ) {
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map<String, dynamic>) {
      return decoded;
    }
    final message = decoded is Map ? decoded['message']?.toString() : null;
    throw Exception(message ?? fallbackMessage);
  }
}

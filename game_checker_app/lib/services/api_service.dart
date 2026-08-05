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

    if (definedBaseUrl.trim().isNotEmpty) {
      return _normalizeBaseUrl(definedBaseUrl);
    }

    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL wajib diisi saat build release. Gunakan URL API produksi Azure.',
      );
    }

    return _normalizeBaseUrl(_devBaseUrl);
  }

  static String _normalizeBaseUrl(String rawBaseUrl) {
    final sanitized = rawBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (sanitized.endsWith('/api')) {
      return sanitized;
    }

    return '$sanitized/api';
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

  static Future<List<dynamic>> searchOrImportGames(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Endpoint ini bisa dipakai tanpa auth kalau Anda mau.
      // Tapi current server route menggunakan middleware throttle saja.
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/games/search').replace(
            queryParameters: {'query': query},
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // Firebase token tidak wajib untuk endpoint ini, tapi boleh.
            if (user != null)
              'Authorization': 'Bearer ${await user.getIdToken()}',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return decoded['data'] as List<dynamic>;
      }
      return [];
    }

    throw Exception(
      _parseErrorMessage(response.body, 'Gagal mencari game di Steam.'),
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

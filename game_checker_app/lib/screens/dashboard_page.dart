import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'result_page.dart'; // Menghubungkan ke halaman hasil yang baru

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _appIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _appIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchGameData(String appId) async {
    setState(() {
      _isLoading = true;
    });

    String url = "http://192.168.1.10:8000/api/games/check";

    try {
      Dio dio = Dio();
      Response response = await dio.post(
        url,
        data: {'app_id': appId},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      setState(() {
        _isLoading = false;
      });

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
      setState(() {
        _isLoading = false;
      });

      String pesanError = 'Gagal terhubung ke server.';
      if (e is DioException && e.response != null) {
        final dataLengkap = e.response?.data;
        if (dataLengkap is Map && dataLengkap.containsKey('message')) {
          pesanError = dataLengkap['message'];
        } else {
          pesanError =
              'Terjadi kesalahan pada server (Status: ${e.response?.statusCode})';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pesanError,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PROYEK-1: GAME CHECKER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SPESIFIKASI LAPTOP KAMU',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.laptop_windows,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      'Sistem Operasi',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    trailing: Text(
                      'Windows 10/11 64-bit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.developer_board,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      'Processor (CPU)',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    trailing: Text(
                      'AMD / Intel Core',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  ListTile(
                    leading: Icon(Icons.memory, color: Colors.blueAccent),
                    title: Text(
                      'RAM Terpasang',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    trailing: Text(
                      '8 GB Shared (2GB iGPU)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: Colors.white10, height: 1),
                  ),
                  ListTile(
                    leading: Icon(Icons.storage, color: Colors.blueAccent),
                    title: Text(
                      'Sisa Storage',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    trailing: Text(
                      '150 GB',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            const Text(
              'CEK KELAYAKAN GAME VIA STEAM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appIdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Masukkan App ID Steam (Contoh: 271590)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        String inputId = _appIdController.text.trim();
                        if (inputId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Silakan masukkan App ID terlebih dahulu!',
                              ),
                            ),
                          );
                          return;
                        }
                        _fetchGameData(inputId);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cek Kelayakan Game',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

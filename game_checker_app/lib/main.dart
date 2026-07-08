import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const GameCheckerApp());
}

class GameCheckerApp extends StatelessWidget {
  const GameCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROYEK-1: Game Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const DashboardPage(),
    );
  }
}

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

  // FUNGSI UTAMA UNTUK MENEMBAK API LARAVEL
  Future<void> _fetchGameData(String appId) async {
    setState(() {
      _isLoading = true;
    });

    String url = "http://192.168.1.10:8000/api/games/check";

    try {
      Dio dio = Dio();

      // Kirim request POST ke Laravel dengan membawa app_id dan header JSON
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

      String pesanError = 'Gagal terhubung: $e';

      // MENGINTIP PESAN ASLI DARI LARAVEL
      if (e is DioException && e.response != null) {
        pesanError = 'Ditolak Laravel (422): ${e.response?.data}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
            content: Text(pesanError),
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

// ========================================================
// HALAMAN HASIL (Menerima Data Dinamis dari API)
// ========================================================
class ResultPage extends StatelessWidget {
  final dynamic gameData;
  const ResultPage({super.key, required this.gameData});

  @override
  Widget build(BuildContext context) {
    String title = gameData['title'] ?? 'Detail Game';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          backgroundColor: const Color(0xFF1F1F1F),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Minimum'),
              Tab(text: 'Recommended'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildSpecsTab(
              'Spesifikasi Minimum Game',
              gameData['min_os'] ?? '-',
              gameData['min_cpu'] ?? '-',
              "${gameData['min_ram'] ?? '-'} GB",
              gameData['min_gpu'] ?? '-',
              "${gameData['min_storage'] ?? '-'} GB",
            ),
            _buildSpecsTab(
              'Spesifikasi Rekomendasi Game',
              gameData['rec_os'] ?? '-',
              gameData['rec_cpu'] ?? '-',
              "${gameData['rec_ram'] ?? '-'} GB",
              gameData['rec_gpu'] ?? '-',
              "${gameData['rec_storage'] ?? '-'} GB",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green, width: 1.5),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'TERKONEKSI KE LARAVEL',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Data berhasil ditarik dari database lokal. Geser tab ke kanan untuk melihat spesifikasi asli!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsTab(
    String title,
    String os,
    String cpu,
    String ram,
    String gpu,
    String storage,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'OS Game',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                subtitle: Text(
                  os,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                title: const Text(
                  'CPU Game',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                subtitle: Text(
                  cpu,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                title: const Text(
                  'RAM Game',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                subtitle: Text(
                  ram,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                title: const Text(
                  'GPU Game',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                subtitle: Text(
                  gpu,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                title: const Text(
                  'Storage Game',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                subtitle: Text(
                  storage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

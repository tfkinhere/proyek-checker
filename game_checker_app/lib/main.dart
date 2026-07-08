import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _appIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PROYEK-1: GAME CHECKER',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.0),
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
                    leading: Icon(Icons.laptop_windows, color: Colors.blueAccent),
                    title: Text('Sistem Operasi', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    trailing: Text('Windows 10/11 64-bit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(color: Colors.white10, height: 1)),
                  ListTile(
                    leading: Icon(Icons.developer_board, color: Colors.blueAccent),
                    title: Text('Processor (CPU)', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    trailing: Text('AMD / Intel Core', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(color: Colors.white10, height: 1)),
                  ListTile(
                    leading: Icon(Icons.memory, color: Colors.blueAccent),
                    title: Text('RAM Terpasang', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    trailing: Text('8 GB Shared (2GB iGPU)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 36),

            const Text(
              'CEK KELAYAKAN GAME VIA STEAM',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.0),
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
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  String inputId = _appIdController.text.trim();
                  if (inputId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan masukkan App ID terlebih dahulu!')),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultPage(gameId: inputId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Cek Kelayakan Game', 
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String gameId;
  const ResultPage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hasil Cek Game: $gameId'),
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
            _buildSpecsTab('Spesifikasi Minimum Game', 'Windows 10 64-bit', 'Intel Core 2 Quad Q6600', '4 GB', 'NVIDIA 9800 GT', '125 GB'),
            _buildSpecsTab('Spesifikasi Rekomendasi Game', 'Windows 10 64-bit', 'Intel Core i5 3470', '8 GB', 'NVIDIA GTX 660', '125 GB'),
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
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'LAYAK MAIN (RATA KIRI)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
                SizedBox(height: 8),
                Text(
                  'Laptop kamu memenuhi syarat minimum, tetapi di bawah syarat rekomendasi game ini.',
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

  Widget _buildSpecsTab(String title, String os, String cpu, String ram, String gpu, String storage) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(title: const Text('OS Game'), subtitle: Text(os), trailing: const Icon(Icons.check_circle, color: Colors.green)),
              const Divider(color: Colors.white10, height: 1),
              ListTile(title: const Text('CPU Game'), subtitle: Text(cpu), trailing: const Icon(Icons.check_circle, color: Colors.green)),
              const Divider(color: Colors.white10, height: 1),
              ListTile(title: const Text('RAM Game'), subtitle: Text(ram), trailing: const Icon(Icons.check_circle, color: Colors.green)),
              const Divider(color: Colors.white10, height: 1),
              ListTile(title: const Text('GPU Game'), subtitle: Text(gpu), trailing: const Icon(Icons.cancel, color: Colors.red)),
            ],
          ),
        )
      ],
    );
  }
}
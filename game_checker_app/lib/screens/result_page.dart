import 'package:flutter/material.dart';

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
    // --- 1. LOGIKA RAM ---
    double laptopUsableRam = 6.0;
    double minRam = double.tryParse(gameData['min_ram'].toString()) ?? 0.0;
    double recRam = double.tryParse(gameData['rec_ram'].toString()) ?? 0.0;

    String ramTitle = '';
    String ramDesc = '';
    Color ramColor = Colors.grey;
    IconData ramIcon = Icons.help_outline;

    if (laptopUsableRam >= recRam) {
      ramTitle = 'RAM: SANGAT LAYAK';
      ramDesc = 'Siap rata kanan!';
      ramColor = Colors.green;
      ramIcon = Icons.memory;
    } else if (laptopUsableRam >= minRam) {
      ramTitle = 'RAM: LAYAK (RATA KIRI)';
      ramDesc = 'Turunkan grafis agar tidak lag.';
      ramColor = Colors.amber;
      ramIcon = Icons.memory;
    } else {
      ramTitle = 'RAM: TIDAK LAYAK';
      ramDesc = 'Risiko crash sangat tinggi.';
      ramColor = Colors.redAccent;
      ramIcon = Icons.memory;
    }

    // --- 2. LOGIKA STORAGE BARU ---
    double sisaStorageLaptop = 150.0; // Asumsi sisa ruang hard disk 150 GB
    double minStorage =
        double.tryParse(gameData['min_storage'].toString()) ?? 0.0;

    bool isStorageSafe = sisaStorageLaptop >= minStorage;
    String storageTitle = isStorageSafe ? 'STORAGE: AMAN' : 'STORAGE: PENUH';
    String storageDesc = isStorageSafe
        ? 'Sisa ruang (150 GB) cukup untuk menginstal game ini ($minStorage GB).'
        : 'Sisa ruang (150 GB) tidak cukup! Game ini butuh $minStorage GB.';
    Color storageColor = isStorageSafe ? Colors.green : Colors.redAccent;
    IconData storageIcon = isStorageSafe ? Icons.save_alt : Icons.disc_full;

    // --- 3. URL BANNER ---
    String appId = gameData['app_id'].toString();
    String bannerUrl =
        'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              bannerUrl,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white38,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // KOTAK INDIKATOR RAM
          _buildIndicatorBox(ramTitle, ramDesc, ramColor, ramIcon),

          const SizedBox(height: 16),

          // KOTAK INDIKATOR STORAGE
          _buildIndicatorBox(
            storageTitle,
            storageDesc,
            storageColor,
            storageIcon,
          ),
        ],
      ),
    );
  }

  // WIDGET KOTAK INDIKATOR UNTUK DIPAKAI ULANG
  Widget _buildIndicatorBox(
    String title,
    String desc,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
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

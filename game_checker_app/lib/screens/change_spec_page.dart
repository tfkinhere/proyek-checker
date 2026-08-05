import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:searchable_paginated_dropdown/searchable_paginated_dropdown.dart';
import '../theme/app_colors.dart';
import '../utils/glass_snackbar.dart';
import '../services/api_service.dart';
import '../services/spec_refresh_notifier.dart';

class ChangeSpecPage extends StatefulWidget {
  const ChangeSpecPage({super.key});

  @override
  State<ChangeSpecPage> createState() => _ChangeSpecPageState();
}

class _ChangeSpecPageState extends State<ChangeSpecPage> {
  static const String _deviceDesktop = 'Desktop';
  static const String _deviceLaptop = 'Laptop';

  // 1. DAFTAR SISTEM OPERASI
  final List<String> _osList = [
    'Windows 10 64-bit',
    'Windows 11 64-bit',
    'Linux Ubuntu 64-bit',
    'macOS Monterey / Ventura',
  ];

  // 2. DAFTAR LENGKAP PROSESOR DESKTOP (CPU)
  final List<String> _desktopCpuList = [
    'Intel Core i9-14900K',
    'Intel Core i9-13900K',
    'Intel Core i9-12900K',
    'Intel Core i7-14700K',
    'Intel Core i7-13700K',
    'Intel Core i7-12700K',
    'Intel Core i7-11700K',
    'Intel Core i7-10700K',
    'Intel Core i5-14600K',
    'Intel Core i5-13600K',
    'Intel Core i5-12400F',
    'Intel Core i5-11400F',
    'Intel Core i5-10400F',
    'Intel Core i3-13100F',
    'Intel Core i3-12100F',
    'Intel Core i3-10100F',
    'AMD Ryzen 9 7950X3D',
    'AMD Ryzen 9 7900X',
    'AMD Ryzen 9 5950X',
    'AMD Ryzen 9 3900X',
    'AMD Ryzen 7 7800X3D',
    'AMD Ryzen 7 7700X',
    'AMD Ryzen 7 5800X3D',
    'AMD Ryzen 7 5700X',
    'AMD Ryzen 7 3700X',
    'AMD Ryzen 5 7600X',
    'AMD Ryzen 5 5600X',
    'AMD Ryzen 5 3600',
    'AMD Ryzen 5 2600',
    'AMD Ryzen 3 3300X',
    'AMD Ryzen 3 3100',
    'Intel UHD Graphics / Integrated CPU',
    'AMD Radeon Vega Integrated',
  ];

  // 3. DAFTAR LENGKAP CPU UNTUK LAPTOP / NOTEBOOK
  final List<String> _laptopCpuList = [
    'Intel Core i9-14900HX',
    'Intel Core i9-13980HX',
    'Intel Core i9-12900HX',
    'Intel Core i7-14700HX',
    'Intel Core i7-13700HX',
    'Intel Core i7-12700H',
    'Intel Core i7-11800H',
    'Intel Core i7-10870H',
    'Intel Core i5-13500H',
    'Intel Core i5-13420H',
    'Intel Core i5-12500H',
    'Intel Core i5-11400H',
    'Intel Core i5-10300H',
    'Intel Core i3-1125G4',
    'Intel Core i3-1115G4',
    'Intel Core i7-1260P',
    'Intel Core i5-1240P',
    'Intel Core i7-13620H',
    'Intel Core Ultra 7 155H',
    'Intel Core Ultra 5 125H',
    'AMD Ryzen 9 7945HX',
    'AMD Ryzen 9 7940HX',
    'AMD Ryzen 9 7940HS',
    'AMD Ryzen 9 6900HX',
    'AMD Ryzen 7 8845HS',
    'AMD Ryzen 7 7840HS',
    'AMD Ryzen 7 7735HS',
    'AMD Ryzen 7 6800H',
    'AMD Ryzen 7 5800H',
    'AMD Ryzen 7 5700U',
    'AMD Ryzen 5 7640HS',
    'AMD Ryzen 5 7535HS',
    'AMD Ryzen 5 6600H',
    'AMD Ryzen 5 5600H',
    'AMD Ryzen 5 5625U',
    'AMD Ryzen 5 5500U',
    'AMD Ryzen 5 7520U',
    'AMD Ryzen 5 7430U',
    'AMD Ryzen 3 7320U',
    'AMD Ryzen 3 5300U',
    'AMD Ryzen 3 3200U',
    'AMD Ryzen 7 5800U',
    'AMD Ryzen 7 7730U',
  ];

  // 4. DAFTAR LENGKAP KARTU GRAFIS DESKTOP (GPU)
  final List<String> _desktopGpuList = [
    'NVIDIA RTX 4090',
    'NVIDIA RTX 4080 Super',
    'NVIDIA RTX 4080',
    'NVIDIA RTX 4070 Ti Super',
    'NVIDIA RTX 4070 Ti',
    'NVIDIA RTX 4070 Super',
    'NVIDIA RTX 4070',
    'NVIDIA RTX 4060 Ti',
    'NVIDIA RTX 4060',
    'NVIDIA RTX 3090 Ti',
    'NVIDIA RTX 3090',
    'NVIDIA RTX 3080 Ti',
    'NVIDIA RTX 3080',
    'NVIDIA RTX 3070 Ti',
    'NVIDIA RTX 3070',
    'NVIDIA RTX 3060 Ti',
    'NVIDIA RTX 3060',
    'NVIDIA RTX 3050',
    'NVIDIA RTX 2080 Ti',
    'NVIDIA RTX 2080 Super',
    'NVIDIA RTX 2070 Super',
    'NVIDIA RTX 2060 Super',
    'NVIDIA RTX 2060',
    'NVIDIA GTX 1660 Ti',
    'NVIDIA GTX 1660 Super',
    'NVIDIA GTX 1660',
    'NVIDIA GTX 1650 Super',
    'NVIDIA GTX 1650',
    'NVIDIA GTX 1080 Ti',
    'NVIDIA GTX 1080',
    'NVIDIA GTX 1070 Ti',
    'NVIDIA GTX 1070',
    'NVIDIA GTX 1060 6GB',
    'NVIDIA GTX 1060 3GB',
    'NVIDIA GTX 1050 Ti',
    'NVIDIA GTX 750 Ti',
    'AMD RX 7900 XTX',
    'AMD RX 7900 XT',
    'AMD RX 7800 XT',
    'AMD RX 7700 XT',
    'AMD RX 7600 XT',
    'AMD RX 7600',
    'AMD RX 6950 XT',
    'AMD RX 6900 XT',
    'AMD RX 6800 XT',
    'AMD RX 6700 XT',
    'AMD RX 6600 XT',
    'AMD RX 6600',
    'AMD RX 6500 XT',
    'AMD RX 5700 XT',
    'AMD RX 5600 XT',
    'AMD RX 5500 XT',
    'AMD RX 580 8GB',
    'AMD RX 570 4GB',
    'AMD RX 480',
    'Intel Arc A770 16GB',
    'Intel Arc A750',
    'Intel Arc A580',
    'Intel Arc A380',
    'Intel UHD / Iris Xe Integrated',
    'AMD Radeon Vega Integrated VGA',
  ];

  // 5. DAFTAR LENGKAP GPU UNTUK LAPTOP / NOTEBOOK
  final List<String> _laptopGpuList = [
    'NVIDIA RTX 4090 Laptop GPU',
    'NVIDIA RTX 4080 Laptop GPU',
    'NVIDIA RTX 4070 Laptop GPU',
    'NVIDIA RTX 4060 Laptop GPU',
    'NVIDIA RTX 4050 Laptop GPU',
    'NVIDIA RTX 3080 Ti Laptop GPU',
    'NVIDIA RTX 3080 Laptop GPU',
    'NVIDIA RTX 3070 Ti Laptop GPU',
    'NVIDIA RTX 3070 Laptop GPU',
    'NVIDIA RTX 3060 Laptop GPU',
    'NVIDIA RTX 3050 Ti Laptop GPU',
    'NVIDIA RTX 3050 Laptop GPU',
    'NVIDIA GTX 1650 Laptop GPU',
    'NVIDIA GTX 1660 Ti Laptop GPU',
    'NVIDIA GTX 1050 Ti Laptop GPU',
    'NVIDIA MX550',
    'NVIDIA MX450',
    'NVIDIA MX350',
    'NVIDIA MX250',
    'AMD Radeon RX 7900M',
    'AMD Radeon RX 7800M',
    'AMD Radeon RX 7700S',
    'AMD Radeon RX 7600S',
    'AMD Radeon RX 6850M XT',
    'AMD Radeon RX 6800M',
    'AMD Radeon RX 6700M',
    'AMD Radeon RX 6650M',
    'AMD Radeon RX 6600M',
    'AMD Radeon RX 6500M',
    'AMD Radeon RX 5600M',
    'AMD Radeon RX 5500M',
    'AMD Radeon RX Vega 8',
    'AMD Radeon Vega 7',
    'AMD Radeon Vega 8',
    'Intel Arc A770M',
    'Intel Arc A730M',
    'Intel Arc A570M',
    'Intel Arc A550M',
    'Intel Arc A370M',
    'Intel Iris Xe Graphics',
    'Intel UHD Graphics',
  ];

  String _selectedDeviceType = _deviceDesktop;
  String _selectedDesktopCpu = 'Intel Core i5-12400F';
  String _selectedDesktopGpu = 'NVIDIA GTX 1650';
  String _selectedLaptopCpu = 'Intel Core i7-12700H';
  String _selectedLaptopGpu = 'NVIDIA RTX 3060 Laptop GPU';
  String _selectedOs = 'Windows 11 64-bit';
  double _ramValue = 8.0;
  double _storageValue = 256.0;

  bool _isSaving = false;
  bool _isLoadingData =
      true; // <-- 1. KUNCI PEMUTUS RACE CONDITION: Tahan layar sebelum data siap!

  @override
  void initState() {
    super.initState();
    _loadSavedSpecs();
  }

  // 2. UPGRADE FUNGSI LOAD: Cek server Laravel dulu, kalau gagal baru baca memori HP
  Future<void> _loadSavedSpecs() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Prioritas 1: Ambil data spek langsung dari server Laravel agar 100% akurat
      final serverData = await ApiService.fetchHomeData();
      final specs = serverData['user_active_specs'];

      if (specs != null && mounted) {
        final loadedCpu =
            (specs['cpu'] ?? prefs.getString('user_cpu') ?? _selectedDesktopCpu)
                .toString();
        final loadedGpu =
            (specs['gpu'] ?? prefs.getString('user_gpu') ?? _selectedDesktopGpu)
                .toString();
        final loadedDeviceType =
            prefs.getString('user_device_type') ??
            _inferDeviceType(loadedCpu, loadedGpu);
        setState(() {
          _selectedOs = specs['os'] ?? prefs.getString('user_os') ?? _osList[1];
          _selectedDeviceType = loadedDeviceType;
          _selectedDesktopCpu = _desktopCpuList.contains(loadedCpu)
              ? loadedCpu
              : _selectedDesktopCpu;
          _selectedDesktopGpu = _desktopGpuList.contains(loadedGpu)
              ? loadedGpu
              : _selectedDesktopGpu;
          _selectedLaptopCpu = _laptopCpuList.contains(loadedCpu)
              ? loadedCpu
              : _selectedLaptopCpu;
          _selectedLaptopGpu = _laptopGpuList.contains(loadedGpu)
              ? loadedGpu
              : _selectedLaptopGpu;
          _ramValue = (specs['ram'] ?? prefs.getDouble('user_ram') ?? 8)
              .toDouble();
          _storageValue =
              (specs['storage'] ?? prefs.getDouble('user_storage') ?? 256)
                  .toDouble();
          _isLoadingData = false; // Data siap, izinkan layar merender!
        });
        return;
      }
    } catch (e) {
      debugPrint(
        'Offline / Gagal tarik dari server, menggunakan memori HP: $e',
      );
    }

    // Prioritas 2: Jika offline/server gagal, gunakan simpanan lokal HP (SharedPreferences)
    if (mounted) {
      final savedCpu = prefs.getString('user_cpu') ?? _selectedDesktopCpu;
      final savedGpu = prefs.getString('user_gpu') ?? _selectedDesktopGpu;
      setState(() {
        _selectedOs = prefs.getString('user_os') ?? _osList[1];
        _selectedDeviceType =
            prefs.getString('user_device_type') ??
            _inferDeviceType(savedCpu, savedGpu);
        _selectedDesktopCpu = _desktopCpuList.contains(savedCpu)
            ? savedCpu
            : _selectedDesktopCpu;
        _selectedDesktopGpu = _desktopGpuList.contains(savedGpu)
            ? savedGpu
            : _selectedDesktopGpu;
        _selectedLaptopCpu = _laptopCpuList.contains(savedCpu)
            ? savedCpu
            : _selectedLaptopCpu;
        _selectedLaptopGpu = _laptopGpuList.contains(savedGpu)
            ? savedGpu
            : _selectedLaptopGpu;
        _ramValue = prefs.getDouble('user_ram') ?? 8.0;
        _storageValue = prefs.getDouble('user_storage') ?? 256.0;
        _isLoadingData = false; // Data siap, izinkan layar merender!
      });
    }
  }

  Future<void> _saveSpecs() async {
    setState(() {
      _isSaving = true;
    });

    final isLaptop = _selectedDeviceType == _deviceLaptop;
    final selectedCpu = isLaptop ? _selectedLaptopCpu : _selectedDesktopCpu;
    final selectedGpu = isLaptop ? _selectedLaptopGpu : _selectedDesktopGpu;

    // A. Simpan di memori lokal HP (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_os', _selectedOs);
    await prefs.setString('user_device_type', _selectedDeviceType);
    await prefs.setString('user_cpu', selectedCpu);
    await prefs.setString('user_gpu', selectedGpu);
    await prefs.setDouble('user_ram', _ramValue);
    await prefs.setDouble('user_storage', _storageValue);

    // B. Kirim ke Database Laravel via ApiService
    bool isServerSaved = await ApiService.saveUserSpecs(
      os: _selectedOs,
      cpu: selectedCpu,
      gpu: selectedGpu,
      ram: _ramValue.toInt(),
      storage: _storageValue.toInt(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (isServerSaved) {
      // Beri tahu dashboard agar auto-refresh memakai spek terbaru.
      SpecRefreshNotifier.notifyChanged();
      GlassSnackBar.show(context, 'Spesifikasi berhasil disimpan ke Database!');
      Navigator.pop(context, true);
    } else {
      GlassSnackBar.show(
        context,
        'Tersimpan di HP, namun gagal sinkron ke server MySQL.',
      );
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SPESIFIKASI PC / LAPTOP SAYA',
          style: GoogleFonts.figtree(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      // 3. LOGIKA PENAHAN LAYAR: Tampilkan loading muter sampai data benar-benar siap!
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ketik untuk mencari CPU dan GPU kamu. Spesifikasi ini dipakai untuk menghitung kelayakan game secara otomatis.',
                            style: GoogleFonts.figtree(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1. DROPDOWN OS
                  _buildSectionTitle('JENIS PERANGKAT'),
                  const SizedBox(height: 8),
                  _buildDeviceTypeSelector(),
                  const SizedBox(height: 24),

                  // 2. DROPDOWN OS
                  _buildSectionTitle('SISTEM OPERASI (OS)'),
                  const SizedBox(height: 8),
                  _buildOsDropdown(),
                  const SizedBox(height: 24),

                  // 3. SEARCHABLE DROPDOWN CPU
                  _buildSectionTitle(
                    _isLaptopMode ? 'PROSESOR LAPTOP (CPU)' : 'PROSESOR (CPU)',
                  ),
                  const SizedBox(height: 8),
                  _buildSearchableCard(
                    key: ValueKey<String>('cpu-$_selectedDeviceType'),
                    hint: _currentCpuValue,
                    items: _currentCpuOptions,
                    value: _currentCpuValue,
                    onChanged: (val) {
                      if (val != null && val.isNotEmpty) {
                        setState(() {
                          if (_isLaptopMode) {
                            _selectedLaptopCpu = val;
                          } else {
                            _selectedDesktopCpu = val;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. SEARCHABLE DROPDOWN GPU
                  _buildSectionTitle(
                    _isLaptopMode
                        ? 'KARTU GRAFIS LAPTOP (GPU)'
                        : 'KARTU GRAFIS (GPU)',
                  ),
                  const SizedBox(height: 8),
                  _buildSearchableCard(
                    key: ValueKey<String>('gpu-$_selectedDeviceType'),
                    hint: _currentGpuValue,
                    items: _currentGpuOptions,
                    value: _currentGpuValue,
                    onChanged: (val) {
                      if (val != null && val.isNotEmpty) {
                        setState(() {
                          if (_isLaptopMode) {
                            _selectedLaptopGpu = val;
                          } else {
                            _selectedDesktopGpu = val;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  // 5. SLIDER RAM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('KAPASITAS RAM'),
                      Text(
                        '${_ramValue.toInt()} GB',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4EE2C0),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF4EE2C0),
                      inactiveTrackColor: AppColors.bottomNav,
                      thumbColor: Colors.white,
                      overlayColor: const Color(
                        0xFF4EE2C0,
                      ).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _ramValue,
                      min: 4,
                      max: 64,
                      divisions: 15,
                      label: '${_ramValue.toInt()} GB',
                      onChanged: (val) => setState(() => _ramValue = val),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. SLIDER STORAGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('SISA PENYIMPANAN (STORAGE)'),
                      Text(
                        '${_storageValue.toInt()} GB',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: AppColors.bottomNav,
                      thumbColor: Colors.white,
                      overlayColor: Colors.blueAccent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _storageValue,
                      min: 20,
                      max: 1000,
                      divisions: 49,
                      label: '${_storageValue.toInt()} GB',
                      onChanged: (val) => setState(() => _storageValue = val),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // TOMBOL SIMPAN
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveSpecs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.blueAccent.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Menyimpan ke Server...'
                            : 'Simpan Spesifikasi PC/Laptop',
                        style: GoogleFonts.figtree(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  bool get _isLaptopMode => _selectedDeviceType == _deviceLaptop;

  List<String> get _currentCpuOptions =>
      _isLaptopMode ? _laptopCpuList : _desktopCpuList;

  List<String> get _currentGpuOptions =>
      _isLaptopMode ? _laptopGpuList : _desktopGpuList;

  String get _currentCpuValue =>
      _isLaptopMode ? _selectedLaptopCpu : _selectedDesktopCpu;

  String get _currentGpuValue =>
      _isLaptopMode ? _selectedLaptopGpu : _selectedDesktopGpu;

  String _inferDeviceType(String cpu, String gpu) {
    final cpuMatchesLaptop = _laptopCpuList.contains(cpu);
    final gpuMatchesLaptop = _laptopGpuList.contains(gpu);
    return cpuMatchesLaptop || gpuMatchesLaptop
        ? _deviceLaptop
        : _deviceDesktop;
  }

  Widget _buildDeviceTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _deviceChip(
              label: 'Desktop / PC',
              selected: !_isLaptopMode,
              onTap: () => setState(() => _selectedDeviceType = _deviceDesktop),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _deviceChip(
              label: 'Laptop',
              selected: _isLaptopMode,
              onTap: () => setState(() => _selectedDeviceType = _deviceLaptop),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryAccent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primaryAccent
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.figtree(
            color: selected ? AppColors.primaryAccent : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.figtree(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildOsDropdown() {
    final validValue = _osList.contains(_selectedOs)
        ? _selectedOs
        : _osList.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          dropdownColor: AppColors.bottomNav,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white54,
          ),
          style: GoogleFonts.figtree(color: Colors.white, fontSize: 14),
          onChanged: (val) => setState(() => _selectedOs = val!),
          items: _osList
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchableCard({
    Key? key,
    required String hint,
    required List<String> items,
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bottomNav,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SearchableDropdown<String>(
        key: key,
        hintText: Text(
          value.isEmpty ? hint : _formatListLabel(value),
          style: GoogleFonts.figtree(color: Colors.white, fontSize: 14),
        ),
        searchHintText: _isLaptopMode
            ? 'Ketik untuk mencari CPU/GPU laptop (misal: H, HX, U, Laptop GPU)...'
            : 'Ketik untuk mencari (misal: RTX, Ryzen, Core i5)...',
        hasTrailingClearIcon: false,
        trailingIcon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white54,
        ),
        items: items
            .map(
              (e) => SearchableDropdownMenuItem<String>(
                value: e,
                label: _formatListLabel(e),
                child: Text(
                  _formatListLabel(e),
                  style: GoogleFonts.figtree(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        value: value,
      ),
    );
  }

  String _formatListLabel(String value) {
    final deviceLabel = _isLaptopMode ? 'Laptop' : 'Desktop';
    final normalized = value.trim();

    if (_isLaptopMode) {
      if (_currentCpuOptions.contains(normalized)) {
        return '$normalized ($deviceLabel)';
      }
      if (_currentGpuOptions.contains(normalized)) {
        return '$normalized ($deviceLabel)';
      }
    } else {
      if (_currentCpuOptions.contains(normalized)) {
        return '$normalized ($deviceLabel)';
      }
      if (_currentGpuOptions.contains(normalized)) {
        return '$normalized ($deviceLabel)';
      }
    }

    return normalized;
  }
}

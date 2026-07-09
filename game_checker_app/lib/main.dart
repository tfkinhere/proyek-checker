import 'package:flutter/material.dart';
import 'screens/dashboard_page.dart'; // Mengambil halaman dashboard dari folder screens
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Wajib ditambahkan jika main() menggunakan async
  await Firebase.initializeApp(); // Menyalakan mesin Firebase

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

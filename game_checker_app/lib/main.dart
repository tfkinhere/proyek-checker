import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:game_checker_app/services/auth_gate.dart';
// ✅ hapus import dashboard_page dan login_page karena sudah ditangani AuthGate

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: const AuthGate(),
    );
  }
}

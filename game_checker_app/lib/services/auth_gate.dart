import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import 'package:game_checker_app/screens/main_nav_page.dart'; // ✅ tetap ada

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ Ganti DashboardPage() menjadi MainNavigationPage()
          if (snapshot.hasData) {
            return const MainNavigationPage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}

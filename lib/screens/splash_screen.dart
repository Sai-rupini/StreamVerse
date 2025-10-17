import 'package:flutter/material.dart';
import 'package:movie/screens/dashboard_page.dart'; // Ensure this import is correct
import 'package:movie/screens/welcome_page.dart';
import 'package:movie/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    bool loggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      if (loggedIn) {
        // --- CORRECTION HERE ---
        // Changed from 'const DashboardPage()' to 'DashboardPage()'
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      ),
    );
  }
}
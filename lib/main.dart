import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const RelksApp());
}

class RelksApp extends StatelessWidget {
  const RelksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RELKS PunchIn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        primaryColor: const Color(0xFF1E6FD9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E6FD9),
          primary: const Color(0xFF1E6FD9),
          secondary: const Color(0xFFD9222A),
          surface: Colors.white,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E6FD9)),
            ),
            SizedBox(height: 24),
            Text(
              "Initializing...",
              style: TextStyle(
                color: Color(0xFF1E6FD9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
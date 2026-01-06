import 'package:chatapp/repository/screens/bottomnav/bottomnavigationscreen.dart';
import 'package:chatapp/repository/screens/onboarding/onboardingscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // optional splash delay

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // User already logged in → BottomNavScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavScreen(currentUserId: user.uid),
        ),
      );
    } else {
      // User not logged in → OnBoardingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnBoardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

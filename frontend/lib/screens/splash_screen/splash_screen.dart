import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/screens/wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int dotCount = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Loading dots animation
    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });

    // Splash duration → go to Wrapper
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Wrapper()),
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/Splash_Screen_BG.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO PLACEHOLDER
                SizedBox(
                  height: 140,
                  width: 140,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 24),

                // APP NAME
                const Text(
                  'BraineX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // TAGLINE
                const Text(
                  'Upload • Scan • Improve',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 60),

                // LOADING TEXT
                Text(
                  'Getting things ready${"." * dotCount}',
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

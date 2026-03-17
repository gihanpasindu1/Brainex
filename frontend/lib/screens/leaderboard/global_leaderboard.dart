import 'package:flutter/material.dart';

class GlobalLeaderboard extends StatelessWidget {
  const GlobalLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: const Center(
        child: Text(
          "Leaderboard",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home.dart';
import 'package:frontend/screens/profile%20screen/profile_screen.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_2.dart';
import 'package:frontend/widgets/premium_bottom_nav.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  // List of the main screens that correspond to the bottom nav tabs
  final List<Widget> _screens = [
    const BrainexHome(), // 0: Home
    const AIStudyPlanPage(), // 1: Plan
    const Scaffold(
      backgroundColor: Color(0xFF0D1026),
      body: Center(
        child: Text(
          "Leaderboard Coming Soon",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    ), // 2: Leaderboard (Placeholder)
    const ProfileScreen(), // 3: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to extend behind the navbar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

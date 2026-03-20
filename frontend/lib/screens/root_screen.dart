import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home.dart';
import 'package:frontend/screens/profile%20screen/profile_screen.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_setup.dart' as frontend;
import 'package:frontend/screens/leaderboard/leaderboard_page.dart';
import 'package:frontend/widgets/premium_bottom_nav.dart';

class RootScreen extends StatefulWidget {
  final String userId;
  const RootScreen({super.key, required this.userId});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to extend behind the navbar
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: [
          const BrainexHome(),
          LeaderboardPage(
            userId: widget.userId,
            onBack: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          const ProfileScreen(),
        ][_currentIndex > 1 ? _currentIndex - 1 : _currentIndex],
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const frontend.AIStudyPlanSetupPage()),
            );
            return;
          }
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

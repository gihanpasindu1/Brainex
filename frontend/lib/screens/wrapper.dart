import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/root_screen.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';
import 'package:frontend/screens/language/language_screen.dart';
import 'package:frontend/screens/exam_details/exam_details.dart';
import 'package:frontend/screens/splash_screen/splash_screen.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/user_profile_service.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final AuthServices _auth = AuthServices();
  final UserProfileService _profileService = UserProfileService();
  bool _minSplashDurationMet = false;

  @override
  void initState() {
    super.initState();
    // Ensures the actual animated splash screen shows for at least 4.5 seconds
    // to play its animations fully.
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _minSplashDurationMet = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        // If data is loading or we haven't met the minimum splash time,
        // we return the exact same SplashScreen widget. Because it's const, 
        // Flutter reuses the same state and its animations continue smoothly!
        if (!_minSplashDurationMet || snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LanguageScreen();
        }

        if (user.uid == '2zJK3J7TClQ7Sk6uTKMqHgOwpsu2') {
          return const AdminDashboardScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _profileService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (!_minSplashDurationMet || profileSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            final profile = profileSnapshot.data;
            if (profile != null && profile['onboarding_completed'] == true) {
              return const RootScreen();
            } else {
              return const ExamDetails();
            }
          },
        );
      },
    );
  }
}

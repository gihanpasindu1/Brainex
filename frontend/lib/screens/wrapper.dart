import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/root_screen.dart';
import 'package:frontend/screens/language/language_screen.dart';
import 'package:frontend/screens/exam_details/exam_details.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/user_profile_service.dart';

import 'package:frontend/screens/splash_screen/splash_screen.dart';
import 'package:frontend/screens/admin_dashboard_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final AuthServices _auth = AuthServices();
  final UserProfileService _profileService = UserProfileService();
  bool _minSplashFinished = false;

  String? _lastUid;
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _minSplashFinished = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        final bool isAuthLoading = snapshot.connectionState == ConnectionState.waiting;
        final user = snapshot.data;
        final bool isAdmin = user != null && user.uid == '2zJK3J7TClQ7Sk6uTKMqHgOwpsu2';

        // Manage caching the profile future to avoid rebuilding on every setState
        if (user != null && user.uid != _lastUid) {
          _lastUid = user.uid;
          if (isAdmin) {
             _profileFuture = Future.value(null);
          } else {
             _profileFuture = _profileService.getUserProfile(user.uid);
          }
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: user != null ? _profileFuture : Future.value(null),
          builder: (context, profileSnapshot) {
            final bool isProfileLoading = !isAdmin && user != null && profileSnapshot.connectionState == ConnectionState.waiting;
            
            final bool showSplash = isAuthLoading || isProfileLoading || !_minSplashFinished;

            if (showSplash) {
              return const SplashScreen();
            }

            if (user == null) {
              return const LanguageScreen();
            }

            if (isAdmin) {
              return const AdminDashboardScreen();
            }

            final profile = profileSnapshot.data;
            if (profile != null && profile['onboarding_completed'] == true) {
              return RootScreen(userId: user.uid);
            } else {
              return const ExamDetails();
            }
          },
        );
      },
    );
  }
}

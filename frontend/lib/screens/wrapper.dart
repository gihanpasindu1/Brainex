import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/root_screen.dart';
import 'package:frontend/screens/language/language_screen.dart';
import 'package:frontend/screens/exam_details/exam_details.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/user_profile_service.dart';

class Wrapper extends StatelessWidget {
  Wrapper({super.key});

  final AuthServices _auth = AuthServices();
  final UserProfileService _profileService = UserProfileService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LanguageScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _profileService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
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

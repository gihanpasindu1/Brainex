import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/screens/root_screen.dart';
import 'package:frontend/screens/language/language_screen.dart';
import 'package:frontend/services/auth.dart';

class Wrapper extends StatelessWidget {
  Wrapper({super.key});

  final AuthServices _auth = AuthServices();

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

        return const RootScreen();
      },
    );
  }
}

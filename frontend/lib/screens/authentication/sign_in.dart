import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';

class Sign_In extends StatefulWidget {
  const Sign_In({super.key});

  @override
  State<Sign_In> createState() => _Sign_InState();
}

class _Sign_InState extends State<Sign_In> {
  final AuthServices _auth = AuthServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Sign in anonymously'),
          onPressed: () async {
            final result = await _auth.signInAnonymously();
            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign in failed')),
              );
            }
          },
        ),
      ),
    );
  }
}

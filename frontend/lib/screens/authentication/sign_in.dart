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
      appBar: AppBar(title: Text("Sign in")),
      body: ElevatedButton(
        child: const Text(" Sign in anonymously"),
        onPressed: () async {
          dynamic result = await _auth.signInAnonymously();
          if (result == null) {
            print("issue" );
          } else {
            print(result.uid);
          }
        },
      ),
    );
  }
}

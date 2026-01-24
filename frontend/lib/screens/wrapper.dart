import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home() ,
    );
  }
}
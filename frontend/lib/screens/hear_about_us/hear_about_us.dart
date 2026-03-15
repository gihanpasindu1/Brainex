import 'package:flutter/material.dart';

class HearAboutUs extends StatefulWidget {
  const HearAboutUs({super.key});

  @override
  State<HearAboutUs> createState() => _HearAboutUsPageState();
}

class _HearAboutUsPageState extends State<HearAboutUs> {
  String selected = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000428), Color(0xFF004e92)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}

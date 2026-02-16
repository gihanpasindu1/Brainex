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
                const Text(
                  "How did you hear about us?",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 30),

                _radio("Friend / Classmate"),
                _radio("Teacher / School"),
                _radio("Social Media"),
                _radio("YouTube"),
                _radio("Google Search"),
                _radio("Other"),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _radio(String title) {
    return RadioListTile(
      value: title,
      groupValue: selected,
      onChanged: (value) {
        setState(() => selected = value.toString());
      },
      title: Text(title, style: const TextStyle(color: Colors.white)),
      activeColor: Colors.cyanAccent,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:frontend/screens/hear_about_us/hear_about_us.dart';

class ChoosePlan extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const ChoosePlan({super.key, required this.onboardingData});

  @override
  State<ChoosePlan> createState() => _ChoosePlanState();
}

class _ChoosePlanState extends State<ChoosePlan> {
  String? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Choose your plan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                _planCard("Premium", "7 days free\nUnlimited access"),
                const SizedBox(height: 16),
                _planCard("Free", "Core study tools"),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedPlan == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a plan to continue.')),
                        );
                        return;
                      }

                      final data = Map<String, dynamic>.from(widget.onboardingData);
                      data['plan'] = _selectedPlan;

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HearAboutUs(onboardingData: data)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _planCard(String title, String desc) {
    bool isSelected = _selectedPlan == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = title),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withAlpha(80) : Colors.white.withAlpha(25),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

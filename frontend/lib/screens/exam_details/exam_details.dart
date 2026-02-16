import 'package:flutter/material.dart';
import 'package:frontend/screens/choose_plan/choose_plan.dart';

class ExamDetails extends StatelessWidget {
  const ExamDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D2671), Color(0xFF0F2027)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "Exam Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                DropdownButtonFormField(
                  dropdownColor: Colors.black,
                  items: const [
                    DropdownMenuItem(value: "O/L", child: Text("O/L")),
                    DropdownMenuItem(value: "A/L", child: Text("A/L")),
                  ],
                  onChanged: (value) {},
                  decoration: _inputDecoration("Select Grade"),
                ),
                const SizedBox(height: 16),

                TextField(
                  decoration: _inputDecoration("School Name (optional)"),
                ),
                const SizedBox(height: 16),

                TextField(decoration: _inputDecoration("District (optional)")),
                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChoosePlan()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Next"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

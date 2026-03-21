import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/choose_plan/choose_plan.dart';

class ExamDetails extends StatefulWidget {
  const ExamDetails({super.key});

  @override
  State<ExamDetails> createState() => _ExamDetailsState();
}

class _ExamDetailsState extends State<ExamDetails> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  
  String? _selectedGrade;
  String? _selectedYear;

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _unfocus() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D2671), Color(0xFF0F2027)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Personal & Exam Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Full Name *"),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1D2671),
                    style: const TextStyle(color: Colors.white),
                    value: _selectedGrade,
                    items: const [
                      DropdownMenuItem(value: "A/L", child: Text("A/L")),
                    ],
                    onChanged: (value) => setState(() => _selectedGrade = value),
                    decoration: _inputDecoration("Select Grade *"),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1D2671),
                    style: const TextStyle(color: Colors.white),
                    value: _selectedYear,
                    items: const [
                      DropdownMenuItem(value: "2026", child: Text("2026")),
                      DropdownMenuItem(value: "2027", child: Text("2027")),
                      DropdownMenuItem(value: "2028", child: Text("2028")),
                    ],
                    onChanged: (value) => setState(() => _selectedYear = value),
                    decoration: _inputDecoration("Exam Year *"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _schoolController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("School Name (Optional)"),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _districtController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("District (Optional)"),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty || _selectedGrade == null || _selectedYear == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required (*) fields.')),
                          );
                          return;
                        }
                        
                        final user = FirebaseAuth.instance.currentUser;
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChoosePlan(
                            onboardingData: {
                              "name": _nameController.text.trim(),
                              "email": user?.email ?? "",
                              "grade": _selectedGrade,
                              "exam_year": _selectedYear,
                              "school": _schoolController.text.trim(),
                              "district": _districtController.text.trim(),
                            },
                          )),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
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
      fillColor: Colors.white.withAlpha(25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

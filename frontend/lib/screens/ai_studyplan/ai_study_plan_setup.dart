import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_2.dart';

class AIStudyPlanSetupPage extends StatefulWidget {
  const AIStudyPlanSetupPage({super.key});

  @override
  State<AIStudyPlanSetupPage> createState() => _AIStudyPlanSetupPageState();
}

class _AIStudyPlanSetupPageState extends State<AIStudyPlanSetupPage> {
  String _selectedPlan = 'Final Year'; // 'Final Year', 'Term', 'Subject'
  final TextEditingController _weeksController = TextEditingController();
  
  String? _selectedGrade;
  String? _selectedTerm;
  String? _selectedSubject;

  final List<String> _planTypes = ['Final Year', 'Term', 'Subject'];
  final List<String> _grades = ['Grade 9', 'Grade 10', 'Grade 11'];
  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];
  final List<String> _subjects = ['Mathematics', 'Science', 'English', 'History', 'ICT'];

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  void _navigateToPlan() {
    // In a real app we'd pass the parameters to the next screen or a provider here.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AIStudyPlanPage2(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                title: "Study Plan Setup",
                subtitle: "Customize your learning path",
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _glassCard(
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "1. Select Plan Type",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _planTypes.map((type) {
                                  final isSelected = _selectedPlan == type;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPlan = type;
                                        _weeksController.clear();
                                        _selectedGrade = null;
                                        _selectedTerm = null;
                                        _selectedSubject = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [Color(0xFF26D3F9), Color(0xFF9D5DFF)],
                                              )
                                            : null,
                                        color: isSelected ? null : Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _glassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "2. Plan Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_selectedPlan == 'Term') ...[
                              _buildDropdown("Class Grade", _grades, _selectedGrade, (val) => setState(() => _selectedGrade = val)),
                              const SizedBox(height: 12),
                              _buildDropdown("School Term", _terms, _selectedTerm, (val) => setState(() => _selectedTerm = val)),
                              const SizedBox(height: 12),
                            ],
                            
                            if (_selectedPlan == 'Subject') ...[
                              _buildDropdown("Subject", _subjects, _selectedSubject, (val) => setState(() => _selectedSubject = val)),
                              const SizedBox(height: 12),
                            ],
                            
                            // Weeks input is needed for all plans
                            const Text(
                              "Duration (Weeks)",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(_weeksController, "e.g., 4", TextInputType.number),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      _generateButton(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text("Select option", style: TextStyle(color: Colors.white30)),
          isExpanded: true,
          dropdownColor: const Color(0xFF16193A),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF26D3F9)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF26D3F9)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _generateButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF26D3F9), Color(0xFF9D5DFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26D3F9).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _navigateToPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          "Generate Plan Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1222).withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

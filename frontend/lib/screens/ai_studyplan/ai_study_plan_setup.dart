import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_2.dart';
import 'package:frontend/services/study_plan_service.dart';

class AIStudyPlanSetupPage extends StatefulWidget {
  final bool forceNewPlan;
  const AIStudyPlanSetupPage({super.key, this.forceNewPlan = false});

  @override
  State<AIStudyPlanSetupPage> createState() => _AIStudyPlanSetupPageState();
}

class _AIStudyPlanSetupPageState extends State<AIStudyPlanSetupPage> {
  String _selectedPlan = 'Final Year'; // 'Final Year', 'Term', 'Subject'
  final TextEditingController _weeksController = TextEditingController();

  String? _selectedGrade;
  String? _selectedTerm;

  final List<String> _planTypes = ['Final Year', 'Term'];
  final List<String> _grades = [
    'Grade 12',
    'Grade 13',
  ]; // Mapped to A/L standard
  final List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];
  final Map<String, Map<String, List<String>>> _syllabusMappings = {
    '12': {
      'Term 1': [
        'Unit 1: Basic Concepts of ICT',
        'Unit 2: Introduction to Computer',
        'Unit 3: Data Representation'
      ],
      'Term 2': [
        'Unit 4: Digital Circuits',
        'Unit 5: Operating Systems',
        'Unit 6: Data Communication & Networking'
      ],
      'Term 3': [
        'Unit 7: System Analysis & Design',
        'Unit 8: Database Management'
      ]
    },
    '13': {
      'Term 1': ['Unit 9: Programming'],
      'Term 2': [
        'Unit 10: Web Development',
        'Unit 11: Internet of Things (IoT)'
      ],
      'Term 3': [
        'Unit 12: ICT in Business',
        'Unit 13: New Trends in ICT'
      ]
    }
  };

  final List<String> _allSubjects = [
    'Unit 1: Basic Concepts of ICT',
    'Unit 2: Introduction to Computer',
    'Unit 3: Data Representation',
    'Unit 4: Digital Circuits',
    'Unit 5: Operating Systems',
    'Unit 6: Data Communication & Networking',
    'Unit 7: System Analysis & Design',
    'Unit 8: Database Management',
    'Unit 9: Programming',
    'Unit 10: Web Development',
    'Unit 11: Internet of Things (IoT)',
    'Unit 12: ICT in Business',
    'Unit 13: New Trends in ICT',
  ];

  List<String> _selectedSubjects = [];

  bool _isLoading = false;
  bool _isCheckingExistingPlan = true;

  @override
  void initState() {
    super.initState();
    if (!widget.forceNewPlan) {
      _checkExistingPlan();
    } else {
      _isCheckingExistingPlan = false;
    }
  }

  Future<void> _checkExistingPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isCheckingExistingPlan = false);
      return;
    }

    final plans = await StudyPlanService().getUserPlans(user.uid);
    if (!mounted) return;

    if (plans != null && plans.isNotEmpty) {
      final latestPlan = plans.first;
      final planData = {"id": latestPlan['id'], "plan": latestPlan};

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AIStudyPlanPage2(planData: planData),
        ),
      );
    } else {
      setState(() => _isCheckingExistingPlan = false);
    }
  }

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    // 1. Validate Weeks (Duration)
    String weeksText = _weeksController.text.trim();
    if (weeksText.isEmpty) {
      _showError("Please enter the number of weeks.");
      return;
    }

    int? weeks = int.tryParse(weeksText);
    if (weeks == null || weeks <= 0) {
      _showError("Please enter a valid number of weeks (at least 1).");
      return;
    }

    // 2. Validate Term selection (if applicable)
    if (_selectedPlan == 'Term') {
      if (_selectedGrade == null) {
        _showError("Please select a Class Grade.");
        return;
      }
      if (_selectedTerm == null) {
        _showError("Please select a School Term.");
        return;
      }
    }

    // 3. Validate Subject selection (Unit Selection)
    if (_selectedSubjects.isEmpty) {
      _showError("Please select at least one Focus Topic/Unit.");
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      _showError("Please login first.");
      return;
    }

    // Map frontend states to backend schema
    String examType = 'Final Exam';
    if (_selectedPlan == 'Term') {
      examType = 'Term Exam';
    } else if (_selectedPlan == 'Subject') {
      examType = 'Topic-wise Plan';
    }

    String gradeStr = 'Grade 13'; // Default
    if (_selectedGrade != null) {
      if (_selectedGrade!.contains('12'))
        gradeStr = 'Grade 12';
      else
        gradeStr = 'Grade 13';
    }

    int? termNumber;
    if (_selectedTerm != null) {
      if (_selectedTerm!.contains('1'))
        termNumber = 1;
      else if (_selectedTerm!.contains('2'))
        termNumber = 2;
      else if (_selectedTerm!.contains('3'))
        termNumber = 3;
    }


    final request = {
      "user_id": user.uid,
      "exam_type": examType,
      "grade": gradeStr,
      "term_number": termNumber,
      "weak_topics": _selectedSubjects,
      "weeks_to_exam": weeks,
    };

    final response = await StudyPlanService().generateStudyPlan(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response != null && response['plan'] != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AIStudyPlanPage2(planData: response),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to generate plan securely via AI. Please try again.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingExistingPlan) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1123),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF26D3F9)),
        ),
      );
    }

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
                                          _selectedSubjects.clear();
                                        });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF26D3F9),
                                                  Color(0xFF9D5DFF),
                                                ],
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
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
                              _buildDropdown(
                                "Class Grade",
                                _grades,
                                _selectedGrade,
                                (val) => setState(() {
                                  _selectedGrade = val;
                                  _selectedSubjects.clear(); // Reset topics on grade change
                                }),
                              ),
                              const SizedBox(height: 12),
                              _buildDropdown(
                                "School Term",
                                _terms,
                                _selectedTerm,
                                (val) => setState(() {
                                  _selectedTerm = val;
                                  _selectedSubjects.clear(); // Reset topics on term change
                                }),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Weeks input is needed for all plans
                            const Text(
                              "Duration (Weeks)",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              _weeksController,
                              "e.g., 4",
                              TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildSubjectSelectionUI(),

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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
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
          hint: const Text(
            "Select option",
            style: TextStyle(color: Colors.white30),
          ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSubjectSelectionUI() {
    List<String> availableSubjects = [];
    
    if (_selectedPlan == 'Final Year') {
      availableSubjects = _allSubjects;
    } else if (_selectedPlan == 'Term') {
      if (_selectedGrade != null && _selectedTerm != null) {
        // Extract '12' or '13' from 'Grade 12'
        String gradeKey = _selectedGrade!.replaceAll(RegExp(r'[^0-9]'), '');
        if (_syllabusMappings.containsKey(gradeKey) && 
            _syllabusMappings[gradeKey]!.containsKey(_selectedTerm)) {
          availableSubjects = List.from(_syllabusMappings[gradeKey]![_selectedTerm]!);
        }
      }
    }

    if (availableSubjects.isEmpty) {
      if (_selectedPlan == 'Term') {
        return _glassCard(
          child: const Padding(
             padding: EdgeInsets.symmetric(vertical: 8.0),
             child: Text(
               "Please select a Grade and Term to view available topics.",
               style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
             ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    bool allSelected = _selectedSubjects.length == availableSubjects.length && availableSubjects.isNotEmpty;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "3. Focus Topics/Units",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (allSelected) {
                      _selectedSubjects.clear();
                    } else {
                      _selectedSubjects = List.from(availableSubjects);
                    }
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  allSelected ? "Deselect All" : "Select All",
                  style: const TextStyle(
                    color: Color(0xFF26D3F9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Select the units you want the AI to focus on in your study plan.",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          const SizedBox(height: 16),
          ...availableSubjects.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSubjects.remove(subject);
                    } else {
                      _selectedSubjects.add(subject);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF26D3F9).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF26D3F9).withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? const Color(0xFF26D3F9) : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType type,
  ) {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        onPressed: _isLoading ? null : _generatePlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}

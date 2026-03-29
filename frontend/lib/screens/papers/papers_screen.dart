import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_setup.dart' as frontend;
import 'exam_screen.dart';

class PapersScreen extends StatefulWidget {
  const PapersScreen({super.key});

  @override
  State<PapersScreen> createState() => _PapersScreenState();
}

class _PapersScreenState extends State<PapersScreen> {
  int bottomIndex = 1;
  bool isModelPapers = true;
  bool isLoading = false;
  bool isSuccess = false;
  bool isFetchingPapers = true;
  List<dynamic> generatedPapers = [];
  String? loadingPaperId; // Track which paper is being fetched
  String? selectedPaperType = 'Term Paper';
  String? selectedDifficulty = 'Medium';
  String? selectedGrade;
  String? selectedTerm;
  String? selectedSubject;
  String? selectedYear;
  List<String> availablePastYears = [];

  final List<String> paperTypes = ['Term Paper', 'Subject Paper', 'Final year'];
  final List<String> difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> grades = ['Grade-12', 'Grade-13'];
  final List<String> terms = ['1st Term', '2nd Term', '3rd Term'];
  final List<String> subjects = [
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
  final List<String> years = ['2023', '2022', '2021', '2020', '2019', '2018'];

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  Future<void> _fetchPapers() async {
    setState(() => isFetchingPapers = true);
    try {
      Uri uri;
      if (isModelPapers) {
        String apiType = 'Term';
        if (selectedPaperType == 'Final year') {
          apiType = 'Final';
        } else if (selectedPaperType == 'Subject Paper') {
          apiType = 'Subject';
        }
        String query = "paper_type=$apiType";
        // ONLY send grade/term if NOT a Final paper (Finals conceptually encompass many units)
        if (apiType != 'Final') {
          if (selectedGrade != null) {
            query += "&grade=${Uri.encodeComponent(selectedGrade!)}";
          }
          if (selectedTerm != null) {
            query += "&term=${Uri.encodeComponent(selectedTerm!)}";
          }
        }
        
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          query += "&user_id=${user.uid}";
        }
        
        uri = Uri.parse("http://10.0.2.2:8000/modelpapers?$query");
      } else {
        // Fetch official past papers registry
        uri = Uri.parse("http://10.0.2.2:8000/pastpapers");
      }

      print("NETWORK: Fetching from $uri");
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      print("NETWORK: Result status ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("NETWORK: Received ${data.length} papers");
        if (mounted) {
          setState(() {
            generatedPapers = data;
            if (!isModelPapers) {
              // Extract unique years and sort DESC
              final yrs = data
                  .where((e) => e['year'] != null)
                  .map((e) => e['year'].toString())
                  .toSet()
                  .toList();
              yrs.sort((a, b) => b.compareTo(a));
              availablePastYears = yrs;
            }
          });
        }
      } else {
        print("NETWORK ERROR: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Failed to fetch papers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not refresh papers: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isFetchingPapers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // soft dark overlay / shapes
              Positioned(
                right: -120,
                top: 120,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(140),
                  ),
                ),
              ),

              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildFilterCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle(),
                        const SizedBox(height: 16),
                        _buildPaperListContent(), // Integrated list content
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Stack(
                  children: [
                    Container(
                      color: Colors.black.withValues(alpha: 0.8),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isSuccess
                                ? const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.greenAccent,
                                  size: 64,
                                )
                                : const CircularProgressIndicator(
                                  color: Colors.cyan,
                                ),
                            const SizedBox(height: 24),
                            Text(
                              isSuccess
                                  ? "Paper Generated!\nSuccesfully added to Suggested Papers."
                                  : "Generating Paper with AI...\nThis usually takes 1-3 minutes",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => setState(() => isLoading = false),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        currentIndex: bottomIndex,
        onChanged: (i) => setState(() => bottomIndex = i),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isModelPapers ? "Model Papers" : "Past Papers",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                "Practice like real A/L ICT",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161821),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Model Papers – ICT",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sell, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildToggleSwitch(),
          const SizedBox(height: 20),
          if (isModelPapers) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Paper Type",
                    paperTypes,
                    selectedPaperType,
                    (val) {
                      setState(() => selectedPaperType = val);
                      _fetchPapers();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    "Difficulty",
                    difficulties,
                    selectedDifficulty,
                    (val) {
                      setState(() => selectedDifficulty = val);
                    },
                  ),
                ),
              ],
            ),
            if (selectedPaperType != 'Final year') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown("Grade", grades, selectedGrade, (
                      val,
                    ) {
                      setState(() => selectedGrade = val);
                      _fetchPapers();
                    }, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown("Term", terms, selectedTerm, (val) {
                      setState(() => selectedTerm = val);
                      _fetchPapers();
                    }, fontSize: 11),
                  ),
                ],
              ),
              if (selectedPaperType == 'Subject Paper') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        "Subject",
                        subjects,
                        selectedSubject,
                        (val) {
                          setState(() => selectedSubject = val);
                          _fetchPapers();
                        },
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Select Year",
                    availablePastYears.isNotEmpty ? availablePastYears : years,
                    selectedYear,
                    (val) {
                      setState(() => selectedYear = val);
                      _fetchPapers();
                    },
                  ),
                ),
              ],
            ),
          ],
          if (isModelPapers || selectedYear != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _generatePaper,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.transparent,
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.cyan, Colors.purpleAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 45),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isModelPapers ? "Generate Papers" : "Start",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Filters affect suggested papers",
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isModelPapers = false);
                _fetchPapers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: !isModelPapers
                      ? const LinearGradient(
                          colors: [Colors.cyan, Colors.purpleAccent],
                        )
                      : null,
                  color: !isModelPapers ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Past Papers",
                  style: GoogleFonts.poppins(
                    color: !isModelPapers ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontStyle: !isModelPapers
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isModelPapers = true);
                _fetchPapers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isModelPapers
                      ? const LinearGradient(
                          colors: [Colors.cyan, Colors.purpleAccent],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Model Papers",
                  style: GoogleFonts.poppins(
                    color: isModelPapers ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontStyle: isModelPapers
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    Function(String?) onChanged, {
    double fontSize = 13,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1116),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: fontSize,
            ),
          ),
          dropdownColor: const Color(0xFF1E2029),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: fontSize),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    String titleText = "Suggested Papers";
    if (isModelPapers) {
      if (selectedGrade != null && selectedTerm != null) {
        titleText = "$selectedGrade - $selectedTerm Suggested";
      } else if (selectedGrade != null) {
        titleText = "$selectedGrade Suggested";
      }
    } else {
      if (selectedYear != null) {
        titleText = "Official $selectedYear Past Papers";
      } else {
        titleText = "GCE A/L Past Papers";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titleText,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isModelPapers)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: isFetchingPapers ? null : _fetchPapers,
            tooltip: "Reload suggested papers",
          ),
      ],
    );
  }

  Widget _buildPaperListContent() {
    if (isFetchingPapers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Colors.cyan),
        ),
      );
    }

    if (generatedPapers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Text(
            "No generated papers found.",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    // Grouping by Date
    final Map<String, List<dynamic>> groupedPapers = {};
    for (var paper in generatedPapers) {
      final dateLabel = _formatDate(paper['created_at']);
      if (!groupedPapers.containsKey(dateLabel)) {
        groupedPapers[dateLabel] = [];
      }
      groupedPapers[dateLabel]!.add(paper);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedPapers.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
              child: Text(
                entry.key.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entry.value.map((paper) => _buildPaperCard(paper)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPaperCard(dynamic paper) {
    final title = paper['title'] ?? 'Untitled Paper';
    final duration = paper['duration_min'] ?? 120;
    
    // Check if paper was created in the last 2 minutes to show NEW badge
    bool isNewlyGenerated = false;
    if (paper['created_at'] != null) {
      try {
        final createdAt = DateTime.parse(paper['created_at']).toLocal();
        isNewlyGenerated = DateTime.now().difference(createdAt).inMinutes < 2;
      } catch (_) {}
    }

    return InkWell(
      onTap: () {
        print("!!! PAPER CLICKED: $title (ID: ${paper['id']}) !!!");
        _openPaper(paper);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161821),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isNewlyGenerated) ...[
                        _buildChip('NEW', Colors.greenAccent),
                        const SizedBox(width: 8),
                      ],
                      _buildChip(
                        paper['paper_type'] ?? 'Paper',
                        Colors.cyanAccent,
                      ),
                      const SizedBox(width: 8),
                      if (paper['difficulty'] != null)
                        _buildChip(paper['difficulty'], Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (paper['grade'] != null)
                        _buildInfoLabel(
                          Icons.school,
                          "Grade ${paper['grade']}",
                        ),
                      if (paper['term'] != null)
                        _buildInfoLabel(Icons.calendar_today, paper['term']),
                      _buildInfoLabel(Icons.timer, "${duration}m"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            (loadingPaperId == paper['id'])
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(
                        color: Colors.cyan,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.cyan, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "Start",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Removed old _buildPaperList and moved to integrated content above

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoLabel(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Recent";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0 && now.day == date.day) {
        return "Today";
      } else if (difference.inDays == 1 ||
          (difference.inDays == 0 && now.day != date.day)) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(date); // Friday, Saturday etc
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return "Recent";
    }
  }

  Future<void> _openPaper(dynamic paper) async {
    try {
      final paperId = paper['id'];
      if (paperId == null) {
        print("ERROR: Paper ID is null");
        return;
      }

      setState(() => loadingPaperId = paperId.toString());

      Uri uri;
      if (paperId.toString().startsWith("past_")) {
        // Retrieve virtual official paper by year
        final year = paper['year'];
        uri = Uri.parse('http://10.0.2.2:8000/pastpapers/$year');
      } else {
        uri = Uri.parse('http://10.0.2.2:8000/modelpapers/$paperId');
      }

      print("NETWORK: Fetching paper from $uri");
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      print("NETWORK: Status ${response.statusCode}");

      if (response.statusCode == 200) {
        final paperData = jsonDecode(response.body);
        if (paperData == null || (paperData['questions'] as List).isEmpty) {
          _showErrorAlert("Paper found, but it has no questions.");
          return;
        }

        if (mounted) {
          print("ACTION: Navigating to Exam Screen...");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ModelPaperOverviewScreen(paperData: paperData),
            ),
          );
        }
      } else {
        _showErrorAlert(
          "Server error: ${response.statusCode}\nBody: ${response.body}",
        );
      }
    } catch (e) {
      print("CRITICAL ERROR: $e");
      _showErrorAlert("Connection failed: $e\n\nIs your backend running?");
    } finally {
      if (mounted) {
        setState(() => loadingPaperId = null);
      }
    }
  }

  void _showErrorAlert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161821),
        title: const Text("Oops!", style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePaper() async {
    if (!isModelPapers) {
      if (selectedYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a year first')),
        );
        return;
      }

      // Directly open the paper instead of just generating it
      _openPaper({
        'id': 'past_$selectedYear',
        'year': selectedYear,
        'paper_type': 'Past Paper',
        'title': 'Official G.C.E. A/L $selectedYear Past Paper',
        'duration_min': 120,
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      // mapping Term formats
      String? backendTerm;
      if (selectedTerm != null) {
        if (selectedTerm!.contains('1st')) {
          backendTerm = 'Term 1';
        } else if (selectedTerm!.contains('2nd'))
          backendTerm = 'Term 2';
        else if (selectedTerm!.contains('3rd'))
          backendTerm = 'Term 3';
      }

      // map Paper Type
      String apiType = 'Term';
      if (selectedPaperType == 'Final year') {
        apiType = 'Final';
      } else if (selectedPaperType == 'Subject Paper')
        apiType = 'Subject';

      String gradeVal = selectedGrade?.replaceAll('Grade-', '') ?? '13';

      final Map<String, dynamic> payload = {
        "paper_type": apiType,
        "difficulty": selectedDifficulty ?? "Medium",
        "count": 1,
        "mcq_count": 50,
        "user_id": FirebaseAuth.instance.currentUser?.uid,
      };

      if (apiType == 'Term' || apiType == 'Subject') {
        payload["grade"] = gradeVal;
        payload["term"] = backendTerm;
      }
      if (apiType == 'Subject') {
        payload["topic"] = selectedSubject;
      }

      // Typically you'd pull URL from an environment/config var
      final uri = Uri.parse('http://10.0.2.2:8000/modelpapers/generate');

      final response = await http
          .post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 300));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> newPapers = data['created'] ?? [];

        if (mounted) {
          // Show success state
          setState(() {
            isSuccess = true;
            // Prepend new papers so they appear at the top
            generatedPapers = [...newPapers, ...generatedPapers];
          });

          // Wait 2 seconds so user sees the success icon
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            setState(() {
              isLoading = false;
              isSuccess = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Success! Your ${newPapers.length > 1 ? "papers are" : "AI paper is"} now in the Suggested Papers list.',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // 2. Refresh full list in background to sync any other metadata
            unawaited(_fetchPapers());
          }
        }
      } else {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${response.statusCode} - ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}

/* ------------------------------ BOTTOM NAV ---------------------------- */

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: t('nav_home'),
                  active: currentIndex == 0,
                  onTap: () {
                    onChanged(0);
                    Navigator.maybePop(context);
                  },
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: t('nav_plan'),
                  active: currentIndex == 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const frontend.AIStudyPlanSetupPage()),
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: t('nav_leaderboard'),
                  active: currentIndex == 2,
                  onTap: () => onChanged(2),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: t('nav_profile'),
                  active: currentIndex == 3,
                  onTap: () => onChanged(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: active
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.9),
                    Colors.purpleAccent.withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.22),
                    blurRadius: 16,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : Colors.white60),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: active ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

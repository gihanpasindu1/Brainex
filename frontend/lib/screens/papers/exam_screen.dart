import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:frontend/services/backend_config.dart';
import 'feedback_screen.dart';

class ModelPaperOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> paperData;

  const ModelPaperOverviewScreen({super.key, required this.paperData});

  @override
  State<ModelPaperOverviewScreen> createState() =>
      _ModelPaperOverviewScreenState();
}

class _ModelPaperOverviewScreenState extends State<ModelPaperOverviewScreen> {
  int currentQuestionIndex = 0;
  List<dynamic> questions = [];
  bool isLoading = false;
  bool isSubmitting = false;

  late Timer _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();

    // Initialize timer from paper data (default 120 mins)
    final int durationMins = widget.paperData['duration_min'] ?? 120;
    _secondsRemaining = durationMins * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        _submitExam(); // Auto submit if time runs out
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Map<int, String?> selectedAnswers = {};

  void _loadQuestions() {
    setState(() {
      questions = widget.paperData['questions'] ?? [];
      isLoading = false;
    });
  }

  void _selectAnswer(String letter) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = letter;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _prevQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitExam() async {
    if (questions.isEmpty) return;

    // Confirm submission
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161821),
        title: Text(
          "Submit Exam",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to submit your answers?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Submit",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isSubmitting = true);

    try {
      // Prepare results payload
      final List<Map<String, dynamic>> results = [];
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final selected = selectedAnswers[i];
        final correct = q['correct_answer'];
        results.add({
          "question": q['question'],
          "topic": q['topic'] ?? "General",
          "is_correct": selected == correct,
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final submissionId = const Uuid().v4();
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/modelpapers/analyze'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": currentUser?.uid,
          "paper_id": widget.paperData['id'],
          "submission_id": submissionId,
          "results": results,
        }),
      );

      if (response.statusCode == 200) {
        final analysis = jsonDecode(response.body);
        if (mounted) {
          // Use push instead of pushReplacement to allow 'Review Answers' to work properly
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PerformanceFeedbackScreen(
                analysis: analysis,
                paperTitle: widget.paperData['title'] ?? 'Model Paper',
                questions: questions,
                selectedAnswers: selectedAnswers,
              ),
            ),
          ).then((_) {
            // Optional: Handle returning from results if needed
          });
        }
      } else {
        throw Exception("Failed to analyze results: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.paperData['title'] ?? 'Model Paper';
    int duration = widget.paperData['duration_min'] ?? 120;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116), // Dark aesthetic background
      body: Stack(
        children: [
          // Simplified soft dark overlay for performance
          Positioned(
            left: -80,
            top: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF512DA8).withValues(alpha: 0.15),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(title, duration),
                if (isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.cyan),
                    ),
                  )
                else if (questions.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No questions available",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else ...[
                  _buildProgressIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildQuestionCard(),
                    ),
                  ),
                  _buildBottomControls(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, int duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4.0, right: 12.0),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "MCQ Section • Answer all questions",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Time Left",
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_secondsRemaining),
                  style: GoogleFonts.poppins(
                    color: _secondsRemaining < 300
                        ? Colors.redAccent
                        : Colors.amberAccent[100],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    double progress = questions.isEmpty
        ? 0
        : (currentQuestionIndex + 1) / questions.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161821).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              Text(
                "Q ${currentQuestionIndex + 1} / ${questions.length}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              color: Colors.purpleAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final currentQ = questions[currentQuestionIndex];
    final String questionText =
        currentQ['question'] ?? 'No question text provided.';
    final String topic = currentQ['topic'] ?? 'General';
    final String? imageUrl = currentQ['image_url'];
    Map<String, dynamic> options = currentQ['options'] ?? {};

    // Sort to ensure A, B, C, D order
    var sortedKeys = options.keys.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161821).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${currentQuestionIndex + 1}",
            style: GoogleFonts.poppins(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            questionText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    "Image not available",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Topic: $topic",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...sortedKeys.map((key) => _buildOptionCard(key, options[key])),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String letter, String text) {
    bool isSelected = selectedAnswers[currentQuestionIndex] == letter;

    return GestureDetector(
      onTap: () => _selectAnswer(letter),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyan.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white10,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.cyan
                    : Colors.white.withValues(alpha: 0.1),
              ),
              child: Text(
                letter,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  text,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prev button
          GestureDetector(
            onTap: _prevQuestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161821),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_left, color: Colors.white70, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "Prev",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // Next Button
          GestureDetector(
            onTap: _nextQuestion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161821),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Next",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_right,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Submit
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Submit",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

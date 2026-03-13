import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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
  bool isLoading = true;
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

      final uri = Uri.parse('http://10.0.2.2:8000/modelpapers/analyze');
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"results": results}),
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
}

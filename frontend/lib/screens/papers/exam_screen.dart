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
  }
}

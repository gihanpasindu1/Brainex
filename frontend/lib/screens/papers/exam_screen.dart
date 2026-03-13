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
}

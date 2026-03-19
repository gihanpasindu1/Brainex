import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/backend_config.dart';

import 'friend_challenge_exam_screen.dart';

class GlobalChallengeExamScreen extends StatefulWidget {
  const GlobalChallengeExamScreen({
    super.key,
    required this.challengeId,
    required this.userId,
    required this.title,
    required this.durationSeconds,
    required this.questions,
  });

  final String challengeId;
  final String userId;
  final String title;
  final int durationSeconds;
  final List<dynamic> questions;

  @override
  State<GlobalChallengeExamScreen> createState() =>
      _GlobalChallengeExamScreenState();
}

class _GlobalChallengeExamScreenState extends State<GlobalChallengeExamScreen> {
  late Timer _timer;
  late int _secondsRemaining;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  final Map<String, String> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _submitChallenge(autoSubmit: true);
        return;
      }
      setState(() => _secondsRemaining--);
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
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveProgress() async {
    try {
      final progressUri = Uri.parse(
        '${BackendConfig.baseUrl}/global-challenges/${widget.challengeId}/progress',
      );
      await http.post(
        progressUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'answers': _selectedAnswers,
        }),
      );
    } catch (_) {
      // Best-effort save so the exam flow stays responsive.
    }
  }

  Future<void> _submitChallenge({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF161821),
          title: Text(
            'Submit Challenge',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Text(
            'Submit your answers now?',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _saveProgress();

      final submitUri = Uri.parse(
        '${BackendConfig.baseUrl}/global-challenges/${widget.challengeId}/submit',
      );
      final submitResponse = await http.post(
        submitUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'answers': _selectedAnswers,
        }),
      );

      if (submitResponse.statusCode != 200) {
        throw Exception(submitResponse.body);
      }

      final result = jsonDecode(submitResponse.body) as Map<String, dynamic>;

      final resultsUri = Uri.parse(
        '${BackendConfig.baseUrl}/global-challenges/${widget.challengeId}/results',
      );
      final leaderboardResponse = await http.get(resultsUri);
      final leaderboard = leaderboardResponse.statusCode == 200
          ? (jsonDecode(leaderboardResponse.body) as Map<String, dynamic>)
          : <String, dynamic>{'leaderboard': []};

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FriendChallengeResultScreen(
            title: widget.title,
            result: result,
            leaderboard:
                leaderboard['leaderboard'] as List<dynamic>? ?? const [],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: SafeArea(
        child: questions.isEmpty
            ? Center(
                child: Text(
                  'No questions available',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
            : Column(
                children: [
                  _Header(
                    title: widget.title,
                    subtitle: 'Global Challenge',
                    timeLeft: _formatTime(_secondsRemaining),
                    onBack: () => Navigator.maybePop(context),
                  ),
                  _Progress(
                    current: _currentQuestionIndex + 1,
                    total: questions.length,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _QuestionCard(
                        index: _currentQuestionIndex,
                        question:
                            questions[_currentQuestionIndex]
                                as Map<String, dynamic>,
                        selectedAnswer:
                            _selectedAnswers[(questions[_currentQuestionIndex]
                                    as Map<String, dynamic>)['question_id']
                                as String],
                        onSelect: (answer) {
                          final questionId =
                              (questions[_currentQuestionIndex]
                                      as Map<String, dynamic>)['question_id']
                                  as String;
                          setState(() => _selectedAnswers[questionId] = answer);
                          _saveProgress();
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _currentQuestionIndex > 0
                                ? () => setState(() => _currentQuestionIndex--)
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Prev'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _currentQuestionIndex < questions.length - 1
                                ? () => setState(() => _currentQuestionIndex++)
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitChallenge,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF8A5CFF),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.timeLeft,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final String timeLeft;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              timeLeft,
              style: GoogleFonts.poppins(
                color: Colors.amberAccent[100],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161821),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              Text(
                'Q $current / $total',
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
              value: total == 0 ? 0 : current / total,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: Colors.purpleAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedAnswer,
    required this.onSelect,
  });

  final int index;
  final Map<String, dynamic> question;
  final String? selectedAnswer;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = Map<String, dynamic>.from(
      question['options'] as Map? ?? const {},
    );
    final keys = options.keys.toList()..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161821),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1}',
            style: GoogleFonts.poppins(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question['question'] as String? ?? '',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...keys.map(
            (key) => GestureDetector(
              onTap: () => onSelect(key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: selectedAnswer == key
                      ? Colors.cyan.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedAnswer == key
                        ? Colors.cyanAccent
                        : Colors.white10,
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
                        color: selectedAnswer == key
                            ? Colors.cyan
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        key,
                        style: GoogleFonts.poppins(
                          color: selectedAnswer == key
                              ? Colors.black
                              : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          options[key].toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

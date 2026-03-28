import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceFeedbackScreen extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final String paperTitle;
  final List<dynamic>? questions;
  final Map<int, String?>? selectedAnswers;

  const PerformanceFeedbackScreen({
    super.key,
    required this.analysis,
    required this.paperTitle,
    this.questions,
    this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final int score = analysis['score'] ?? 0;
    final int total = analysis['total'] ?? 0;
    final double percentage = (analysis['percentage'] ?? 0).toDouble();
    final int xpAwarded = (analysis['xp_awarded'] as num?)?.toInt() ?? 0;
    final int? totalXp = (analysis['total_xp'] as num?)?.toInt();
    final List<dynamic> strongAreas = analysis['strong_areas'] ?? [];
    final List<dynamic> improvementAreas = analysis['improvement_areas'] ?? [];
    final List<dynamic> suggestions = analysis['suggestions'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1116),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreCard(score, total, percentage),
                    if (xpAwarded > 0) ...[
                      const SizedBox(height: 20),
                      _buildXpCard(xpAwarded, totalXp),
                    ],
                    const SizedBox(height: 20),
                    _buildAreasSection(
                      title: "Strong Areas",
                      subtitle: "Sections where you performed well",
                      items: strongAreas,
                      color: const Color(0xFF00BFA5),
                    ),
                    const SizedBox(height: 20),
                    _buildAreasSection(
                      title: "Needs Improvement",
                      subtitle: "Sections where you lost more marks",
                      items: improvementAreas,
                      color: const Color(0xFFFF4081),
                    ),
                    const SizedBox(height: 20),
                    _buildHowToImprove(suggestions),
                    const SizedBox(height: 30),
                    if (questions != null) ...[
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 20),
                      Text(
                        "Detailed Answers & Explanations",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._buildReviewList(),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Performance Feedback",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  paperTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int score, int total, double percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Score",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$score / $total",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${percentage.toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Color(0xFF00BFA5),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard(int xpAwarded, int? totalXp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "XP Earned",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            "+$xpAwarded XP",
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (totalXp != null) ...[
            const SizedBox(height: 6),
            Text(
              "Total XP: $totalXp",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAreasSection({
    required String title,
    required String subtitle,
    required List<dynamic> items,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 15),
          if (items.isEmpty)
            const Text(
              "No data for this section",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => _buildTag(item.toString(), color))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHowToImprove(List<dynamic> suggestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How to Improve",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            const Text(
              "Review all subject materials thoroughly.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            )
          else
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "• ",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    Expanded(
                      child: Text(
                        s.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildReviewList() {
    if (questions == null) return [];
    
    return List.generate(questions!.length, (index) {
      final q = questions![index];
      final Map<int, String?> answers = selectedAnswers ?? {};
      final String? selected = answers[index];
      final String correct = q['correct_answer'] ?? '';
      final bool isCorrect = selected == correct;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isCorrect ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q['question'] ?? "",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAnswerLine("Your Answer: ", selected ?? "No Answer", isCorrect ? Colors.greenAccent : Colors.redAccent),
            if (!isCorrect)
              _buildAnswerLine("Correct Answer: ", correct, Colors.greenAccent),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                q['explanation'] ?? "No explanation.",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAnswerLine(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 32),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1116),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                "Back to Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

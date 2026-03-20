import 'package:flutter/material.dart';

class WeeklyActivitiesPage extends StatefulWidget {
  final Map<String, dynamic>? weekData;
  final int totalWeeks;
  final String? createdAt;
  const WeeklyActivitiesPage({super.key, this.weekData, this.totalWeeks = 8, this.createdAt});

  @override
  State<WeeklyActivitiesPage> createState() => _WeeklyActivitiesPageState();
}

class _WeeklyActivitiesPageState extends State<WeeklyActivitiesPage> {
  final Set<int> _completedDays = {};

  void _onDayCompleted(int dayNumber, bool isCompleted) {
    setState(() {
      if (isCompleted) {
        _completedDays.add(dayNumber);
      } else {
        _completedDays.remove(dayNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalDays = widget.weekData != null && widget.weekData!['days'] != null
        ? (widget.weekData!['days'] as List).length
        : 5;
    final double progress = totalDays > 0 ? _completedDays.length / totalDays : 0.62;

    String dateRange = "Nov 25 - Dec 1";
    if (widget.createdAt != null && widget.weekData != null) {
      try {
        final DateTime startDate = DateTime.parse(widget.createdAt!);
        final int weekIndex = (widget.weekData!['week_number'] as int? ?? 1) - 1;
        final DateTime weekStart = startDate.add(Duration(days: weekIndex * 7));
        final DateTime weekEnd = weekStart.add(const Duration(days: 6));

        const List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final String startStr = "${months[weekStart.month - 1]} ${weekStart.day}";
        final String endStr = "${months[weekEnd.month - 1]} ${weekEnd.day}";
        dateRange = "$startStr - $endStr";
      } catch (e) {
        // fallback
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                _TopHeader(
                  title: widget.weekData != null
                      ? "Week ${widget.weekData!['week_number']} Activities"
                      : "Weekly Activities",
                  subtitle: widget.weekData != null
                      ? "${widget.weekData!['focus_area']}"
                      : "Your plan-linked quests",
                  onBack: () => Navigator.maybePop(context),
                ),

                const SizedBox(height: 16),

                // Week selector / range bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          "Week ${widget.weekData?['week_number'] ?? 1} of ${widget.totalWeeks}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateRange,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Progress + label
                Column(
                  children: [
                    _GradientProgressBar(value: progress), // Dynamically updated
                    const SizedBox(height: 8),
                    Text(
                      widget.weekData != null
                          ? "${_completedDays.length} / $totalDays activities completed"
                          : "3 / 5 activities completed",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  widget.weekData != null
                      ? "AI Study Advice: ${widget.weekData!['study_advice']}"
                      : "This Week’s Quests",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                // Quest list
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (widget.weekData != null && widget.weekData!['days'] != null) ...[
                        for (int i = 0; i < (widget.weekData!['days'] as List).length; i++) ...[
                          _DayAccordion(
                            dayData: (widget.weekData!['days'] as List)[i],
                            isInitiallyExpanded: i == 0,
                            onStatusSelected: (status) {
                               final int dayNum = (widget.weekData!['days'] as List)[i]['day_number'] ?? (i + 1);
                               _onDayCompleted(dayNum, status != null);
                            },
                          ),
                        ],
                      ] else ...[
                        const _QuestCard(
                          title: "Quest 1: Review SQL JOIN Notes",
                          subtitle1: "Short Notes → SQL Unit",
                          subtitle2: "25 mins • Badge: “SQL Explorer”",
                          buttonText: "Start",
                        ),
                        const SizedBox(height: 12),
                        const _QuestCard(
                          title: "Quest 2: Chatbot Practice (5 Qs)",
                          subtitle1: "Ask 5 ICT concept questions",
                          subtitle2: "15 mins • Reward: “Curiosity” bonus",
                          buttonText: "Start",
                        ),
                        const SizedBox(height: 12),
                        const _QuestCard(
                          title: "Quest 3: Attempt Model Paper 02",
                          subtitle1: "Timed Exam → Medium Level",
                          subtitle2: "2h • League Points Enabled",
                          buttonText: "Start",
                        ),
                      ],
                      const SizedBox(height: 22),
                      const Center(
                        child: Text(
                          "Completing all quests unlocks the Weekly Chest",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: 6),
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
                    color: Colors.white.withValues(alpha: 0.7),
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

class _DayAccordion extends StatefulWidget {
  final Map<String, dynamic> dayData;
  final bool isInitiallyExpanded;
  final Function(String?)? onStatusSelected;

  const _DayAccordion({required this.dayData, this.isInitiallyExpanded = false, this.onStatusSelected});

  @override
  State<_DayAccordion> createState() => _DayAccordionState();
}

class _DayAccordionState extends State<_DayAccordion> {
  late bool _expanded;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16193A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: Text(
              "Day ${widget.dayData['day_number'] ?? 'X'}: ${widget.dayData['topic'] ?? 'Topic'}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: Icon(
              _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white54,
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _stepRow(Icons.menu_book, "Learn", widget.dayData['learning_step'], Colors.blue),
                  _stepRow(Icons.lightbulb_outline, "Understand", widget.dayData['understanding_step'], Colors.orange),
                  _stepRow(Icons.edit_document, "Practice", widget.dayData['practice_step'], Colors.green),
                  _stepRow(Icons.published_with_changes, "Review", widget.dayData['review_step'], Colors.redAccent),
                  _stepRow(Icons.history, "Revise", widget.dayData['revision_step'], Colors.purpleAccent),
                  _buildCheckpoint(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckpoint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.teal, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Checkpoint",
                  style: TextStyle(color: Colors.teal, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Text(
              widget.dayData['checkpoint'] ?? "Did you finish all tasks? Confidence level:",
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 26.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusButton("Good", Colors.green),
                _statusButton("Average", Colors.orange),
                _statusButton("Weak", Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String label, Color color) {
    final isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle off if already selected
          if (_selectedStatus == label) {
            _selectedStatus = null;
          } else {
            _selectedStatus = label;
          }
        });
        if (widget.onStatusSelected != null) {
          widget.onStatusSelected!(_selectedStatus);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          border: Border.all(color: isSelected ? color : Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _stepRow(IconData icon, String title, String? desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  desc ?? "N/A",
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _GradientProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: Colors.white.withOpacity(0.10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF25C3FF), Color(0xFFB14CFF)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String title;
  final String subtitle1;
  final String subtitle2;
  final String buttonText;

  const _QuestCard({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.black.withOpacity(0.30);
    final borderColor = Colors.white.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle1,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle2,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StartButton(text: buttonText),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final String text;
  const _StartButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25C3FF), Color(0xFFB14CFF)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class WeeklyActivitiesPage extends StatelessWidget {
  final Map<String, dynamic>? weekData;
  const WeeklyActivitiesPage({super.key, this.weekData});

  @override
  Widget build(BuildContext context) {
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
                  title: weekData != null ? "Week ${weekData!['week_number']} Activities" : "Weekly Activities",
                  subtitle: weekData != null ? "${weekData!['focus_area']}" : "Your plan-linked quests",
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
                        child: const Text(
                          "Week 2 of 8",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Nov 25 - Dec 1",
                        style: TextStyle(
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
                    const _GradientProgressBar(value: 0.62), // ~3/5 completed
                    const SizedBox(height: 8),
                    Text(
                      "3 / 5 activities completed",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Week title gradient chip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF25C3FF), Color(0xFFB14CFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Week 1 Activities",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  weekData != null ? "AI Study Advice: ${weekData!['study_advice']}" : "This Week’s Quests",
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
                      if (weekData != null && weekData!['topics_to_cover'] != null) ...[
                        for (int i = 0; i < (weekData!['topics_to_cover'] as List).length; i++) ...[
                          _QuestCard(
                            title: "Quest ${i + 1}: ${(weekData!['topics_to_cover'] as List)[i]}",
                            subtitle1: "Topic Checkpoint",
                            subtitle2: "${weekData!['suggested_hours_per_day']}h / day recommended",
                            buttonText: "Start",
                            isHighlighted: i == 0,
                          ),
                          const SizedBox(height: 12),
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
  final bool isHighlighted;

  const _QuestCard({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.buttonText,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isHighlighted
        ? const Color(0xFF163B2C).withOpacity(0.85)
        : Colors.black.withOpacity(0.30);

    final borderColor = isHighlighted
        ? const Color(0xFF31E7A6).withOpacity(0.25)
        : Colors.white.withOpacity(0.10);

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

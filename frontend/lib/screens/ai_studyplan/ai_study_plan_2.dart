import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_1.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_setup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/study_plan_service.dart';

class AIStudyPlanPage2 extends StatefulWidget {
  final Map<String, dynamic>? planData;
  const AIStudyPlanPage2({super.key, this.planData});

  @override
  State<AIStudyPlanPage2> createState() => _AIStudyPlanPage2State();
}

class _AIStudyPlanPage2State extends State<AIStudyPlanPage2> {
  int selectedTab = 0; // 0 = Term Plan, 1 = Final Plan
  late PageController _pageController;
  bool _isLoading = true;
  Map<String, dynamic>? _termPlanData;
  Map<String, dynamic>? _finalPlanData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedTab);
    _initializePlans();
  }

  Future<void> _initializePlans() async {
    // If a plan was explicitly passed, figure out what type it is.
    if (widget.planData != null) {
      final type =
          widget.planData!['plan']?['exam_type']?.toString().toLowerCase();
      if (type != null && type.contains('term')) {
        _termPlanData = widget.planData;
        selectedTab = 0;
      } else {
        // Default to final if not explicitly term
        _finalPlanData = widget.planData;
        selectedTab = 1;
      }
    }

    // Now fetch all user plans to populate the *other* tab if it exists
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final plans = await StudyPlanService().getUserPlans(user.uid);
        if (plans != null && plans.isNotEmpty) {
          for (var plan in plans) {
            final type = plan['exam_type']?.toString().toLowerCase() ?? '';
            final planData = {"id": plan['id'], "plan": plan};

            if (type.contains('term') && _termPlanData == null) {
              _termPlanData = planData;
            } else if ((type.contains('final') || type.isEmpty) &&
                _finalPlanData == null) {
              _finalPlanData = planData;
            }
          }
        }
      }
    } catch (e) {
      // Handle error gracefully
      print("Error fetching plans: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        // Re-initialize controller if the tab changed due to fetched data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(selectedTab);
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              /// 🔙 Back + Title
              _TopHeader(
                title: widget.planData != null
                    ? "My AI Study Plan"
                    : "AI Study Plan",
                subtitle: "Your personalized path to success",
                onBack: () => Navigator.maybePop(context),
              ),

              const SizedBox(height: 10),

              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF26D3F9)),
                  ),
                )
              else ...[
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _SegmentedTabs(
                  leftText: "Term Plan",
                  rightText: "Final Plan",
                  selectedIndex: selectedTab,
                  onChanged: (i) {
                    setState(() => selectedTab = i);
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => selectedTab = i),
                  children: [
                    // Tab 0: Term Plan
                    _termPlanData != null
                        ? _DynamicPlanView(planData: _termPlanData!)
                        : _NoPlanView(title: "Term Plan"),
                    // Tab 1: Final Plan
                    _finalPlanData != null
                        ? _DynamicPlanView(planData: _finalPlanData!)
                        : _NoPlanView(title: "Final Exam Plan"),
                  ],
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 No Plan View
class _NoPlanView extends StatelessWidget {
  final String title;
  const _NoPlanView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            "No $title Found",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "You haven't generated a $title yet. Create one now to get started!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          _generateButton(context),
        ],
      ),
    );
  }
}


/// 🔹 Dynamic Plan View
class _DynamicPlanView extends StatelessWidget {
  final Map<String, dynamic> planData;

  const _DynamicPlanView({required this.planData});

  @override
  Widget build(BuildContext context) {
    final plan = planData['plan'] ?? {};
    final weeks = plan['weeks'] as List<dynamic>? ?? [];
    final duration = weeks.length;
    final examType = plan['exam_type'] ?? 'Custom Plan';

    // Create timeline items
    List<Widget> timelineWidgets = [];
    for (int i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      timelineWidgets.add(
        _timelineItem(
          color: Colors.cyan,
          title: "Week ${w['week_number']}",
          subtitle: w['focus_area'] ?? 'General Focus',
          isLast: i == weeks.length - 1,
        ),
      );
    }

    // Create weekly activity cards
    List<Widget> weeklyActivityWidgets = [];
    for (int i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      weeklyActivityWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _weeklyCard(
            context,
            "Week ${w['week_number']} Quests",
            "${w['suggested_hours_per_day']}h / day • ${w['focus_area']}",
            const Color(0xFF40C4FF),
            w,
            weeks.length,
            plan['created_at']?.toString(),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 📊 Plan Overview Card
            _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$examType Overview",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Duration: $duration Weeks • Grade: ${plan['grade']}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        "${weeks.isNotEmpty ? weeks[0]['suggested_hours_per_day'] : 2}h / day",
                      ),
                      _chip("AI Powered"),
                      _chip("Personalized"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (plan['ai_advice'] != null &&
                plan['ai_advice'].toString().isNotEmpty) ...[
              _glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Study Advice",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      plan['ai_advice'].toString(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ] else ...[
              const SizedBox(height: 25),
            ],

            const Text(
              "Study Timeline",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// 📍 Timeline Card
            if (timelineWidgets.isNotEmpty)
              _glassCard(child: Column(children: timelineWidgets)),

            const SizedBox(height: 25),

            const Text(
              "Weekly Activities",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...weeklyActivityWidgets,

            const SizedBox(height: 30),

            /// 🚀 Generate Button
            _generateButton(context),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}



/// 🔹 Segmented Tabs Widget (from Short Notes)
class _SegmentedTabs extends StatelessWidget {
  final String leftText;
  final String rightText;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.leftText,
    required this.rightText,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              text: leftText,
              selected: selectedIndex == 0,
              gradient: const LinearGradient(
                colors: [Color(0xFF26D3F9), Color(0xFF9D5DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabPill(
              text: rightText,
              selected: selectedIndex == 1,
              gradient: const LinearGradient(
                colors: [Color(0xFF26D3F9), Color(0xFF9D5DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String text;
  final bool selected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _TabPill({
    required this.text,
    required this.selected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF26D3F9).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 Generate Button
Widget _generateButton(BuildContext context) {
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
          color: const Color(0xFF26D3F9).withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AIStudyPlanSetupPage(forceNewPlan: true),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        "Generate New Plan",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
}

/// 🔹 Glass Card Widget
Widget _glassCard({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1222).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
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

/// 🔹 Chip Widget
Widget _chip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
    ),
  );
}

/// 🔹 Timeline Item
class _timelineItem extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;

  const _timelineItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Weekly Card
Widget _weeklyCard(
  BuildContext context,
  String title,
  String subtitle,
  Color glowColor, [
  Map<String, dynamic>? weekData,
  int totalWeeks = 8,
  String? createdAt,
]) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF16193A).withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
          gradient: LinearGradient(
            colors: [
              glowColor.withOpacity(0.2),
              const Color(0xFF16193A).withOpacity(0.3),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.center,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyActivitiesPage(
                      weekData: weekData,
                      totalWeeks: totalWeeks,
                      createdAt: createdAt,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26D3F9), Color(0xFF9D5DFF)],
                  ),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

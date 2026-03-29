import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/screens/chatbot/chatbot_screen.dart';
import 'package:frontend/screens/shortnote_page/short_notes_page.dart';
import 'package:frontend/screens/ai_studyplan/ai_study_plan_setup.dart';
import 'package:frontend/screens/papers/papers_screen.dart';
import 'package:frontend/screens/activity_challenges/activity_challenges_screen.dart';
import 'package:frontend/services/motivation_service.dart';
import 'package:frontend/screens/notifications/notifications_page.dart';
import 'package:frontend/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Theme data is usually set in main.dart or a theme provider.
    // The user provided code set a specific theme in BrainexApp.
    // We will assume the app's theme is sufficient or wrap this in a Theme if needed.
    // For now, we'll rely on the visual design within the widget (Gradients/Colors).

    return const BrainexHome();
  }
}

class BrainexHome extends StatefulWidget {
  const BrainexHome({super.key});

  @override
  State<BrainexHome> createState() => _BrainexHomeState();
}

class _BrainexHomeState extends State<BrainexHome> {
  bool _isCountdownVisible = true;
  late String _motivationQuote;
  late Color _motivationColor;

  // Countdown timers
  String _days = '0';
  String _hours = '0';
  String _minutes = '0';
  Timer? _timer;
  int? _examYear;

  final List<String> _quotes = [
    'Stay Focused', 'Dream Big', 'Work Hard',
    'Keep Pushing', 'Never Settle', 'Think Big',
    'Aim High', 'Keep Growing', 'Be Great',
    'Stay Sharp', 'Stay Strong', 'Move Forward',
    'Be Bold', 'Push Limits', 'Keep Going',
    'Rise Up', 'Take Action', 'Stay Positive',
    'Work Smart', 'Believe Now', 'No Excuses',
    'Chase Dreams', 'Keep Learning', 'Stay Humble',
    'Own It', 'Think Fast', 'Stay Calm',
    'Show Up', 'Keep Building', 'Go Hard'
  ];

  @override
  void initState() {
    super.initState();
    _shuffleMotivation();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await UserProfileService().getUserProfile(user.uid);
      if (profile != null && profile['exam_year'] != null) {
        final year = int.tryParse(profile['exam_year'].toString());
        if (year != null) {
          setState(() {
            _examYear = year;
          });
          _startCountdown();
        }
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (_examYear == null) return;

    final targetDate = DateTime(_examYear!, 8, 10);
    final now = DateTime.now();
    final difference = targetDate.difference(now);

    if (difference.isNegative) {
      setState(() {
        _days = '0';
        _hours = '0';
        _minutes = '0';
      });
      return;
    }

    setState(() {
      _days = difference.inDays.toString();
      _hours = (difference.inHours % 24).toString();
      _minutes = (difference.inMinutes % 60).toString();
    });
  }

  void _shuffleMotivation() {
    final random = Random();
    _motivationQuote = _quotes[random.nextInt(_quotes.length)];
    _motivationColor = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
    ][random.nextInt(6)];
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                // Premium header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('brainex_title'),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('exam_helper_subtitle'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Language Switcher
                        _GlowIconButton(
                          icon: Icons.language,
                          onTap: () {
                            _showLanguageDialog(context, localeProvider, t);
                          },
                        ),
                        const SizedBox(width: 10),
                        // Logout / Notification (Using Notifications icon for now as per design, but could be logout)
                        // User asked for "language changing option", we added that.
                        // I'll keep the notification icon but maybe double it as logout or just notifications.
                        // For this implementation, I'll add a separate Logout but user design had Notification.
                        // I will add a PopupMenu to the notification icon or just a separate icon?
                        // Let's add the logout functionality to a long press or a separate button?
                        // The existing code had a logout button. I'll add a logout button.
                        _GlowIconButton(
                          icon: Icons.notifications_none,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Countdown (glass)
                _GlassCard(
                  radius: 26,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            t('final_exam_countdown'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCountdownVisible = !_isCountdownVisible;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Text(
                                _isCountdownVisible ? t('hide') : t('show'), // Make sure you have 'show' in localization, or fallback to 'show'
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isCountdownVisible
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    '$_days ${t('days')}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _Pill(
                                        text: '${_hours}h',
                                        glowColor: Colors.cyanAccent,
                                      ),
                                      const SizedBox(width: 10),
                                      _Pill(
                                        text: '${_minutes}m',
                                        glowColor: Colors.cyanAccent,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _GlassCard(
                        radius: 22,
                        padding: const EdgeInsets.all(14),
                        child: _StatRow(
                          title: t('daily_streak'),
                          value: '5 ${t('days')}',
                          icon: Icons.local_fire_department_rounded,
                          iconColor: Colors.orangeAccent,
                          accent: const Color(0x33FFA726),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _shuffleMotivation();
                          });
                        },
                        child: _GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('motivation_title'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: _motivationColor.withValues(alpha: 0.8),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _Pill(
                                text: _motivationQuote,
                                glowColor: _motivationColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text(
                  t('quick_actions'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: Column(
                      children: [
                        // 2x2 grid of 4 action cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.95,
                          children: [
                            _PremiumActionCard(
                              title: t('chatbot'),
                              icon: Icons.chat_bubble_outline_rounded,
                              color: const Color(0xFF38BDF8),
                              subtitle: t('ask_anything'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                            ),
                            _PremiumActionCard(
                              title: t('papers'),
                              icon: Icons.description_outlined,
                              color: const Color(0xFFC084FC),
                              subtitle: t('past_papers'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PapersScreen())),
                            ),
                            _PremiumActionCard(
                              title: t('short_notes'),
                              icon: Icons.menu_book_rounded,
                              color: const Color(0xFF34D399),
                              subtitle: t('quick_review'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShortNotesPage())),
                            ),
                            _PremiumActionCard(
                              title: t('ai_study_plan'),
                              icon: Icons.calendar_today_rounded,
                              color: const Color(0xFFF59E0B),
                              subtitle: t('daily_schedule'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIStudyPlanSetupPage())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Full-width Active Challenges card
                        _PremiumActionCardWide(
                          title: t('active_challenge'),
                          icon: Icons.public_rounded,
                          color: const Color(0xFFFB7185),
                          subtitle: t('compete_live'),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityChallengesScreen())),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleProvider provider,
    Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text(t('language'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, provider, 'English', 'en'),
            _languageOption(context, provider, 'සිංහල', 'si'),
            _languageOption(context, provider, 'தமிழ்', 'ta'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(
    BuildContext context,
    LocaleProvider provider,
    String name,
    String code,
  ) {
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
      trailing: provider.locale?.languageCode == code
          ? const Icon(Icons.check, color: Colors.blueAccent)
          : null,
    );
  }
}

/* ---------------- Premium Components ---------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
}

class _GlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlowIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white70),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color? glowColor;

  const _Pill({required this.text, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: glowColor?.withValues(alpha: 0.5) ??
              Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          color: glowColor != null ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color accent;

  const _StatRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PremiumActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _PremiumActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_PremiumActionCard> createState() => _PremiumActionCardState();
}

class _PremiumActionCardState extends State<_PremiumActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: _GlassCard(
          radius: 26,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.color.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.20),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(widget.icon, color: widget.color),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.white70,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full-width wide card used for Active Challenges ──────────────────────────
class _PremiumActionCardWide extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _PremiumActionCardWide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_PremiumActionCardWide> createState() => _PremiumActionCardWideState();
}

class _PremiumActionCardWideState extends State<_PremiumActionCardWide> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1.0,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: _GlassCard(
          radius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: widget.color.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.30),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.18),
                  border: Border.all(color: widget.color.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav();

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
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: t('nav_home'),
                  active: true,
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: t('nav_plan'),
                  active: false,
                ),
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: t('nav_leaderboard'),
                  active: false,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: t('nav_profile'),
                  active: false,
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
    );
  }
}

//test comment

class _MotivationWidget extends StatefulWidget {
  final String title;
  const _MotivationWidget({required this.title});

  @override
  State<_MotivationWidget> createState() => _MotivationWidgetState();
}

class _MotivationWidgetState extends State<_MotivationWidget> {
  final MotivationService _motivationService = MotivationService();
  late Future<Map<String, dynamic>> _motivationFuture;
  int? _lastQuoteId;

  @override
  void initState() {
    super.initState();
    _fetchMotivation();
  }

  void _fetchMotivation() {
    setState(() {
      _motivationFuture = _motivationService.fetchMotivation(
        lastQuoteId: _lastQuoteId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _fetchMotivation,
                child: const Icon(
                  Icons.refresh,
                  size: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<Map<String, dynamic>>(
            future: _motivationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                );
              }
              String quote = 'Focused learner';
              if (snapshot.hasData && snapshot.data != null) {
                final data = snapshot.data!;
                quote = data['quote']?.toString() ?? quote;
                _lastQuoteId = data['id'] is int ? data['id'] : _lastQuoteId;
              }
              return _Pill(text: quote);
            },
          ),
        ],
      ),
    );
  }
}

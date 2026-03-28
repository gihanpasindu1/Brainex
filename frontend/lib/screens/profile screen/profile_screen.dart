import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/user_profile_service.dart';
import 'package:frontend/screens/profile screen/edit_profile_screen.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/screens/profile screen/about_brainex_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _profileFuture = UserProfileService().getUserProfile(user.uid);
    } else {
      _profileFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0D1026), // Fallback base color
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white70,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Colors.cyanAccent),
                          ),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Error loading profile data", style: TextStyle(color: Colors.white54)),
                          ),
                        );
                      }
                      final profile = snapshot.data!;
                      return Column(
                        children: [
                          _UserCard(
                            profile: profile,
                            onEditComplete: () {
                              setState(() {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  _profileFuture = UserProfileService().getUserProfile(user.uid);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _StatsCard(profile: profile),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // Badges Title
                  const Text(
                    "Badges",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const _GlobalLeagueSection(),
                  const SizedBox(height: 15),
                  const _MasterySection(),
                  const SizedBox(height: 25),

                  // More Title
                  const Text(
                    "More",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const _MoreSection(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        await AuthServices().signOut();
                      },
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// BASE DARK CARD REUSABLE WIDGET
//////////////////////////////////////////////////////////////
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF16193A), // Dark solid color matching Figma
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

//////////////////////////////////////////////////////////////
/// USER CARD
//////////////////////////////////////////////////////////////
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEditComplete;
  const _UserCard({required this.profile, required this.onEditComplete});

  Widget _buildAvatar() {
    final base64String = profile['profile_picture_base64'];
    if (base64String != null && base64String.isNotEmpty) {
      try {
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      } catch (_) {}
    }
    return const Icon(Icons.person, color: Colors.white38, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    final int xp = profile['total_xp'] ?? 0;
    
    Map<String, dynamic> leagueInfo;
    if (xp >= 10000) {
      leagueInfo = {"name": "Diamond League", "color": const Color(0xFF00E5FF)};
    } else if (xp >= 4000) {
      leagueInfo = {"name": "Platinum League", "color": const Color(0xFFE5E4E2)};
    } else if (xp >= 1000) {
      leagueInfo = {"name": "Gold League", "color": const Color(0xFFFFD700)};
    } else if (xp >= 250) {
      leagueInfo = {"name": "Silver League", "color": const Color(0xFFC0C0C0)};
    } else {
      leagueInfo = {"name": "Bronze League", "color": const Color(0xFFCD7F32)};
    }

    return DarkCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing Avatar Ring
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3), // Border width
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00E5FF),
                  Color(0xFFB388FF),
                ], // Cyan to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16193A),
                shape: BoxShape.circle,
              ),
              child: _buildAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  profile['name'] ?? "You",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${profile['grade'] ?? 'Unknown'} • ${profile['exam_year'] ?? 'Unknown'} Batch",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Dynamic League Badge
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: leagueInfo['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      leagueInfo['name'] as String,
                      style: TextStyle(
                        color: leagueInfo['color'] as Color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit Button
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(currentProfile: profile),
                ),
              );
              if (result == true) {
                onEditComplete();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF40C4FF),
                    Color(0xFF8C9EFF),
                  ], // Cyan to Purple tint
                ),
              ),
              child: const Text(
                "Edit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// STATS CARD
//////////////////////////////////////////////////////////////
class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const _StatItem("Streak", "🔥", "5 days", Colors.white),
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
            _StatItem("Papers", "📝", "${profile['papers_completed'] ?? 0}", Colors.white),
            VerticalDivider(
              color: Colors.white.withValues(alpha: 0.1),
              thickness: 1,
            ),
            _StatItem(
              "XP Points",
              "🎯",
              "${profile['total_xp'] ?? 0}",
              const Color(0xFF69F0AE),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String emoji;
  final String value;
  final Color valueColor;

  const _StatItem(this.label, this.emoji, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

//////////////////////////////////////////////////////////////
/// GLOBAL LEAGUE SECTION
//////////////////////////////////////////////////////////////
class _GlobalLeagueSection extends StatelessWidget {
  const _GlobalLeagueSection();

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Global League Badges (Weekly)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF40C4FF), // Cyan
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BadgeBox(Icons.psychology, Colors.purpleAccent),
              _BadgeBox(Icons.emoji_events, Colors.cyanAccent),
              _BadgeBox(Icons.draw, Colors.cyanAccent),
              _BadgeBox(Icons.hourglass_bottom, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  final IconData icon;
  final Color neonColor;

  const _BadgeBox(this.icon, this.neonColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1026), // Darker inner bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: neonColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      // Depending on your actual design, you might use image assets here instead of Icons
      child: Icon(icon, color: neonColor, size: 30),
    );
  }
}

//////////////////////////////////////////////////////////////
/// MASTERY SECTION
//////////////////////////////////////////////////////////////
class _MasterySection extends StatelessWidget {
  const _MasterySection();

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mastery Badges (Unlock only at 100%)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF40C4FF), // Cyan
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Locked Badge Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1026),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white38, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SQL Grandmaster",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "100% required",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Unlocked Badge Card (Glowing gradient border simulation)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(
                    1.5,
                  ), // Gradient border thickness
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00E5FF),
                        Color(0xFFB388FF),
                      ], // Cyan to purple
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB388FF).withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1026),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        // Lightning Icon Circle
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF40C4FF), Color(0xFFB388FF)],
                            ),
                          ),
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Logic Legend",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "100% achieved",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
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
            ],
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// MORE SECTION
//////////////////////////////////////////////////////////////
class _MoreSection extends StatelessWidget {
  const _MoreSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MoreTile(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF40C4FF),
            text: "About Brainex",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutBrainexScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MoreTile(
            icon: Icons.help_outline,
            iconColor: Colors.redAccent,
            text: "Help & Support",
          ),
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback? onTap;

  const _MoreTile({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DarkCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 12),
          ],
        ),
      ),
    );
  }
}

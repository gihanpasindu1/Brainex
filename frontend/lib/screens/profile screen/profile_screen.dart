import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/premium_bottom_nav.dart';
import 'package:frontend/screens/home/home.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF1C1F4A), Color(0xFF0D1026)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 20),
                  Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 25),
                  _UserCard(),
                  SizedBox(height: 25),
                  _StatsCard(),
                  SizedBox(height: 30),
                  _GlobalLeagueSection(),
                  SizedBox(height: 25),
                  _MasterySection(),
                  SizedBox(height: 30),
                  _MoreSection(),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          }
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// GLASS CONTAINER
//////////////////////////////////////////////////////////////

class GlassContainer extends StatelessWidget {
  final Widget child;

  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// USER CARD
//////////////////////////////////////////////////////////////

class _UserCard extends StatelessWidget {
  const _UserCard();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.purple],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "A/L ICT • 2026 Batch",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          /// Lowered Edit Button
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.purple],
                ),
              ),
              child:
                  const Text("Edit", style: TextStyle(color: Colors.white)),
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
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem("🔥", "5 days", "Streak"),
          _StatItem("📄", "14", "Papers"),
          _StatItem("🎯", "78%", "Accuracy"),
        ],
      ),
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
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Global League Badges (Weekly)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View All",
                style: TextStyle(color: Colors.cyan),
              )
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BadgeBox(Icons.psychology),
              _BadgeBox(Icons.emoji_events),
              _BadgeBox(Icons.handshake),
              _BadgeBox(Icons.hourglass_top),
            ],
          )
        ],
      ),
    );
  }
}

class _BadgeBox extends StatelessWidget {
  final IconData icon;
  const _BadgeBox(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.3),
            Colors.blue.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.4),
            blurRadius: 20,
          )
        ],
      ),
      child: Icon(icon, color: Colors.white),
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
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Mastery Badges (Unlock only at 100%)",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "View All",
                style: TextStyle(color: Colors.cyan),
              )
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock, color: Colors.white70),
                      SizedBox(height: 8),
                      Text(
                        "SQL Grandmaster",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text("100% required",
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.cyan],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        "Logic Legend",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text("100% achieved",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          )
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
    return Column(
      children: const [
        _MoreTile(Icons.info, "About Brainex"),
        SizedBox(height: 15),
        _MoreTile(Icons.help, "Help & Support"),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MoreTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child:
                Text(text, style: const TextStyle(color: Colors.white)),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// STAT ITEM
//////////////////////////////////////////////////////////////

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatItem(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style:
              const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
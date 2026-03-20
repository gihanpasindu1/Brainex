import 'package:flutter/material.dart';

enum LeaderboardTab { global, friends }

class LeaderboardPage extends StatefulWidget {
  final LeaderboardTab initialTab;
  const LeaderboardPage({Key? key, this.initialTab = LeaderboardTab.global}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late bool isGlobal;

  @override
  void initState() {
    super.initState();
    isGlobal = widget.initialTab == LeaderboardTab.global;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141933),
      body: Stack(
        children: [
          // Background Gradient at the top
          Container(
            height: 350,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A52E5), Color(0xFF141933)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildToggleBar(),
                const SizedBox(height: 20),
                if (!isGlobal) _buildInviteRow(),
                _buildPodium(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    isGlobal ? "Top 5 This Week" : "Top Friends",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildLeaderboardList(),
                ),
              ],
            ),
          ),
          // Sticky Bottom Card
          Positioned(
            bottom: 80, // Above bottom nav
            left: 20,
            right: 20,
            child: _buildYourPosition(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Text(
                "Leaderboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              isGlobal ? "Global Rankings" : "Friends Rankings",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF22284E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isGlobal = true),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isGlobal
                        ? const LinearGradient(
                            colors: [Color(0xFF2FD1ED), Color(0xFFA155F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Global",
                    style: TextStyle(
                      color: isGlobal ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isGlobal = false),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: !isGlobal
                        ? const LinearGradient(
                            colors: [Color(0xFF2FD1ED), Color(0xFFA155F6)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Friends",
                    style: TextStyle(
                      color: !isGlobal ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Text(
                "Invite friends to compete with you ",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Icon(Icons.link, color: Colors.white70, size: 16),
            ],
          ),
          const Text(
            "Invite",
            style: TextStyle(
              color: Color(0xFF2FD1ED),
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2242).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumItem(
            rank: 2,
            name: isGlobal ? "Student B" : "Nimal",
            xp: isGlobal ? "910 XP" : "510 XP",
            color: const Color(0xFFE2E8F0),
            height: 100,
            avatarRadius: 28,
          ),
          _buildPodiumItem(
            rank: 1,
            name: isGlobal ? "Student A" : "Amaya",
            xp: isGlobal ? "980 XP" : "560 XP",
            color: const Color(0xFFFFD700),
            height: 130,
            avatarRadius: 36,
            isFirst: true,
          ),
          _buildPodiumItem(
            rank: 3,
            name: isGlobal ? "Student C" : "You",
            xp: isGlobal ? "870 XP" : "520 XP",
            color: const Color(0xFFFCA5A5),
            height: 90,
            avatarRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required String xp,
    required Color color,
    required double height,
    required double avatarRadius,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: EdgeInsets.only(top: isFirst ? 15 : 0),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFF22284E),
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst ? 20 : 16,
                  ),
                ),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: 0,
                child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 30),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        Text(
          xp,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final List<Map<String, dynamic>> items = isGlobal
        ? [
            {"rank": 1, "name": "Student A", "sub": "Gold League", "xp": "980 XP"},
            {"rank": 2, "name": "Student B", "sub": "Silver League", "xp": "910 XP"},
            {"rank": 3, "name": "Student C", "sub": "Silver League", "xp": "870 XP"},
            {"rank": 4, "name": "Student D", "sub": "Bronze League", "xp": "840 XP"},
          ]
        : [
            {"rank": 1, "name": "Amaya", "sub": "", "xp": "560 XP"},
            {"rank": 2, "name": "Nimal", "sub": "", "xp": "510 XP"},
            {"rank": 3, "name": "You", "sub": "", "xp": "520 XP"},
          ];

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 160),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2242),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF141933),
                child: Text(
                  item["rank"].toString(),
                  style: TextStyle(
                    color: item["rank"] == 1 ? const Color(0xFFFFD700) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["name"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (item["sub"].toString().isNotEmpty)
                      Text(
                        item["sub"],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                item["xp"],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYourPosition() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FD1ED), Color(0xFFA155F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Your Position",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            isGlobal ? "Rank #12" : "Rank #3",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            isGlobal ? "620 XP" : "520 XP",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

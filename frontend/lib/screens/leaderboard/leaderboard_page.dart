import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/leaderboard_service.dart';

enum LeaderboardTab { global, friends }

class LeaderboardPage extends StatefulWidget {
  final LeaderboardTab initialTab;
  final String userId;
  final VoidCallback? onBack;

  const LeaderboardPage({
    super.key,
    this.initialTab = LeaderboardTab.global,
    required this.userId,
    this.onBack,
  });

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late bool isGlobal;
  final _service = LeaderboardService();

  LeaderboardResult? _result;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    isGlobal = widget.initialTab == LeaderboardTab.global;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final result = await _service.fetchLeaderboard(widget.userId);
    if (!mounted) return;
    setState(() {
      _result = result;
      _isLoading = false;
      _hasError = result == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141933),
      body: Stack(
        children: [
          // Background gradient at the top
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
                // Content area
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
          // Sticky bottom card (only when data loaded)
          if (!_isLoading && !_hasError && _result != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: _buildYourPosition(),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    return _buildLeaderboardContent();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2FD1ED)),
          SizedBox(height: 16),
          Text(
            'Loading rankings...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Could not load leaderboard',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection and try again.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A52E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    final entries = _result!.entries;
    final top3 = entries.take(3).toList();

    return RefreshIndicator(
      color: const Color(0xFF2FD1ED),
      backgroundColor: const Color(0xFF1C2242),
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 160),
        children: [
          _buildPodium(top3),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isGlobal ? 'Top Rankings' : 'Top Friends',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...entries.map((e) => _buildLeaderboardTile(e, widget.userId)),
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
              GestureDetector(
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              // Refresh button
              if (!_isLoading)
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  tooltip: 'Refresh',
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              isGlobal ? 'Global Rankings' : 'Friends Rankings',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    'Global',
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
                    'Friends',
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
                'Invite friends to compete with you ',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Icon(Icons.link, color: Colors.white70, size: 16),
            ],
          ),
          const Text(
            'Invite',
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

  // ─── Podium ───────────────────────────────────────────────────────────────

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // Display order: 2nd, 1st, 3rd
    final hasFirst = top3.isNotEmpty;
    final hasSecond = top3.length >= 2;
    final hasThird = top3.length >= 3;

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
          if (hasSecond)
            _buildPodiumItem(
              entry: top3[1],
              color: const Color(0xFFE2E8F0),
              height: 100,
              avatarRadius: 28,
            )
          else
            const SizedBox(width: 80),
          if (hasFirst)
            _buildPodiumItem(
              entry: top3[0],
              color: const Color(0xFFFFD700),
              height: 130,
              avatarRadius: 36,
              isFirst: true,
            )
          else
            const SizedBox(width: 80),
          if (hasThird)
            _buildPodiumItem(
              entry: top3[2],
              color: const Color(0xFFFCA5A5),
              height: 90,
              avatarRadius: 24,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required LeaderboardEntry entry,
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
                backgroundImage: entry.profilePictureBase64 != null
                    ? _base64ToImage(entry.profilePictureBase64!)
                    : null,
                child: entry.profilePictureBase64 == null
                    ? Text(
                        entry.rank.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isFirst ? 20 : 16,
                        ),
                      )
                    : null,
              ),
            ),
            if (isFirst)
              const Positioned(
                top: 0,
                child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 30),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _firstName(entry.name),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.totalXp} XP',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // ─── List Tile ─────────────────────────────────────────────────────────────

  Widget _buildLeaderboardTile(LeaderboardEntry entry, String currentUserId) {
    final isMe = entry.userId == currentUserId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2A1F5C) : const Color(0xFF1C2242),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isMe ? const Color(0xFF5A52E5) : Colors.white12,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 32,
            child: entry.rank <= 3
                ? Icon(
                    Icons.workspace_premium,
                    color: _rankColor(entry.rank),
                    size: 24,
                  )
                : CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF141933),
                    child: Text(
                      '${entry.rank}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF22284E),
            backgroundImage: entry.profilePictureBase64 != null
                ? _base64ToImage(entry.profilePictureBase64!)
                : null,
            child: entry.profilePictureBase64 == null
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${entry.name} (You)' : entry.name,
                  style: TextStyle(
                    color: isMe ? const Color(0xFF2FD1ED) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${entry.totalXp} XP',
            style: TextStyle(
              color: isMe ? const Color(0xFF2FD1ED) : Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Your Position ─────────────────────────────────────────────────────────

  Widget _buildYourPosition() {
    final myRank = _result?.myRank;
    final myXp = _result?.myXp ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FD1ED), Color(0xFFA155F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A52E5).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Position',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            myRank != null ? 'Rank #$myRank' : 'Unranked',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            '$myXp XP',
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

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFE2E8F0);
      case 3:
        return const Color(0xFFFCA5A5);
      default:
        return Colors.white54;
    }
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  ImageProvider? _base64ToImage(String base64Str) {
    try {
      // Strip data URI prefix if present
      final clean = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      final bytes = base64Decode(clean);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}

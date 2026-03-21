import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'friend_challenge_exam_screen.dart';

class FriendChallengeLobbyScreen extends StatefulWidget {
  const FriendChallengeLobbyScreen({
    super.key,
    required this.challengeData,
    required this.currentUserId,
  });

  final Map<String, dynamic> challengeData;
  final String currentUserId;

  @override
  State<FriendChallengeLobbyScreen> createState() =>
      _FriendChallengeLobbyScreenState();
}

class _FriendChallengeLobbyScreenState
    extends State<FriendChallengeLobbyScreen> {
  bool _isStarting = false;
  Timer? _pollTimer;

  String get _shareUrl => 'brainex://challenge/$_challengeId';

  bool get _isHost =>
      widget.challengeData['host_user_id'] == widget.currentUserId;

  String get _challengeId => widget.challengeData['id'] as String;

  @override
  void initState() {
    super.initState();
    // Guests poll the backend every 3 s until the host starts the challenge.
    if (!_isHost) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _pollForStart(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollForStart() async {
    if (!mounted) return;
    try {
      final uri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/$_challengeId',
      );
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'started') return;

      // Challenge has started — cancel polling and go to exam.
      _pollTimer?.cancel();

      final questionsUri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/$_challengeId/questions'
        '?user_id=${widget.currentUserId}',
      );
      final questionsResponse = await http.get(questionsUri);
      if (!mounted) return;
      if (questionsResponse.statusCode != 200) return;

      final questionData =
          jsonDecode(questionsResponse.body) as Map<String, dynamic>;

      // Calculate true remaining time from server's ends_at so the guest's
      // countdown is in sync with the host, not reset to full duration.
      int durationSeconds =
          (data['duration_seconds'] as num?)?.toInt() ?? 7200;
      final endsAtRaw = data['ends_at'] as String?;
      if (endsAtRaw != null) {
        try {
          final endsAt = DateTime.parse(endsAtRaw).toUtc();
          final now = DateTime.now().toUtc();
          final remaining = endsAt.difference(now).inSeconds;
          if (remaining > 0 && remaining < durationSeconds) {
            durationSeconds = remaining;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FriendChallengeExamScreen(
            challengeId: _challengeId,
            userId: widget.currentUserId,
            title: data['title'] as String? ?? 'Friend Challenge',
            durationSeconds: durationSeconds,
            questions:
                (questionData['questions'] as List<dynamic>? ?? const []),
          ),
        ),
      );
    } catch (_) {
      // Silently ignore poll errors
    }
  }

  Future<void> _shareChallengeLink() async {
    final inviteCode = widget.challengeData['invite_code'] as String? ?? '';
    final title =
        widget.challengeData['title'] as String? ?? 'Friend Challenge';
    await Share.share(
      'Join my BraineX challenge: $title\n'
      'Invite code: $inviteCode\n'
      'Open link: $_shareUrl',
      subject: 'BraineX Friend Challenge',
    );
  }

  Future<void> _copyChallengeLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Challenge link copied'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _startChallenge() async {
    setState(() => _isStarting = true);

    try {
      final startUri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/$_challengeId/start',
      );
      final startResponse = await http.post(
        startUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUserId}),
      );

      if (startResponse.statusCode != 200) {
        throw Exception(startResponse.body);
      }

      final questionsUri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/$_challengeId/questions'
        '?user_id=${widget.currentUserId}',
      );
      final questionsResponse = await http.get(questionsUri);

      if (questionsResponse.statusCode != 200) {
        throw Exception(questionsResponse.body);
      }

      final questionData =
          jsonDecode(questionsResponse.body) as Map<String, dynamic>;
      final durationSeconds =
          (widget.challengeData['duration_seconds'] as num?)?.toInt() ?? 7200;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FriendChallengeExamScreen(
            challengeId: _challengeId,
            userId: widget.currentUserId,
            title:
                widget.challengeData['title'] as String? ?? 'Friend Challenge',
            durationSeconds: durationSeconds,
            questions:
                (questionData['questions'] as List<dynamic>? ?? const []),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants =
        widget.challengeData['participants'] as List<dynamic>? ?? const [];
    final questionCount =
        (widget.challengeData['question_count'] as num?)?.toInt() ?? 0;
    final durationSeconds =
        (widget.challengeData['duration_seconds'] as num?)?.toInt() ?? 0;
    final durationMinutes = (durationSeconds / 60).round();

    return Scaffold(
      backgroundColor: const Color(0xFF090612),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A4BF7), Color(0xFF24173F), Color(0xFF0A0B17)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge Ready',
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Invite code and paper are ready',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFD7DCF9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _LobbyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.challengeData['title'] as String? ??
                            'Friend Challenge',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(
                            label: 'Invite Code',
                            value:
                                widget.challengeData['invite_code']
                                    as String? ??
                                '-',
                          ),
                          _InfoChip(
                            label: 'Questions',
                            value: '$questionCount MCQs',
                          ),
                          _InfoChip(
                            label: 'Duration',
                            value: '$durationMinutes min',
                          ),
                          _InfoChip(
                            label: 'Players',
                            value: '${participants.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyChallengeLink,
                              icon: const Icon(Icons.link_rounded, size: 18),
                              label: const Text('Copy Link'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF3A446A),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareChallengeLink,
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share Link'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7D5DFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _LobbyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isHost ? 'Host Controls' : 'Waiting for Host',
                        style: GoogleFonts.sora(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isHost
                            ? 'Press start when everyone is ready. Sync for all players can be tightened later.'
                            : 'The challenge creator needs to start the paper before participants can begin.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB9C2E6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isHost && !_isStarting
                              ? _startChallenge
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isHost
                                    ? const [
                                        Color(0xFF28D0F4),
                                        Color(0xFFAA5BFF),
                                      ]
                                    : const [
                                        Color(0xFF343C56),
                                        Color(0xFF242B41),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minHeight: 54),
                              child: _isStarting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isHost
                                          ? 'Start Challenge'
                                          : 'Waiting for Host',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                            ),
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

class _LobbyCard extends StatelessWidget {
  const _LobbyCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF101528).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF323B64)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171D34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF293151)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8E98BF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

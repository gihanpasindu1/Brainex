import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'friend_challenge_lobby_screen.dart';

class FriendChallengeEntryScreen extends StatefulWidget {
  const FriendChallengeEntryScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<FriendChallengeEntryScreen> createState() =>
      _FriendChallengeEntryScreenState();
}

class _FriendChallengeEntryScreenState
    extends State<FriendChallengeEntryScreen> {
  Map<String, dynamic>? _challengeData;
  bool _isLoading = true;
  bool _isJoining = false;
  String? _error;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  bool get _isParticipant {
    final participants =
        _challengeData?['participants'] as List<dynamic>? ?? const [];
    final userId = _currentUserId;
    if (userId == null) return false;
    return participants.any(
      (p) => (p as Map<String, dynamic>)['user_id'] == userId,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/${widget.challengeId}',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final challengeData = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _challengeData = challengeData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to open challenge: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinChallenge() async {
    final userId = _currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before joining a challenge.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final uri = Uri.parse(
        'http://10.0.2.2:8000/friend-challenges/${widget.challengeId}/join',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      await _loadChallenge();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF090612),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _challengeData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF090612),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Challenge not found',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final challenge = _challengeData!;
    final participants =
        challenge['participants'] as List<dynamic>? ?? const [];

    if (_isParticipant && _currentUserId != null) {
      return FriendChallengeLobbyScreen(
        challengeData: challenge,
        currentUserId: _currentUserId!,
      );
    }

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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Join Friend Challenge',
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge['title'] as String? ?? 'Friend Challenge',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD7DCF9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101528).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF323B64)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _EntryInfoRow(
                        label: 'Invite Code',
                        value: challenge['invite_code'] as String? ?? '-',
                      ),
                      _EntryInfoRow(
                        label: 'Questions',
                        value: '${challenge['question_count'] ?? 0}',
                      ),
                      _EntryInfoRow(
                        label: 'Participants',
                        value: '${participants.length}',
                      ),
                      _EntryInfoRow(
                        label: 'Status',
                        value: challenge['status'] as String? ?? 'waiting',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _joinChallenge,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF28D0F4), Color(0xFFAA5BFF)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        constraints: const BoxConstraints(minHeight: 54),
                        child: _isJoining
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentUserId == null
                                    ? 'Sign In To Join'
                                    : 'Join Challenge',
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
        ),
      ),
    );
  }
}

class _EntryInfoRow extends StatelessWidget {
  const _EntryInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF8E98BF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

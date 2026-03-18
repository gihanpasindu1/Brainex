import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'friend_challenge_lobby_screen.dart';

class ActivityChallengesScreen extends StatefulWidget {
  const ActivityChallengesScreen({super.key});

  @override
  State<ActivityChallengesScreen> createState() =>
      _ActivityChallengesScreenState();
}

class _ActivityChallengesScreenState extends State<ActivityChallengesScreen> {
  final TextEditingController _challengeNameController =
      TextEditingController();

  static const List<String> _grades = ['12', '13'];
  static const List<String> _examTypes = [
    'Final Exam',
    'Term Exam',
    'Subject Wise',
  ];
  static const List<String> _terms = ['Term 1', 'Term 2', 'Term 3'];
  static const Map<String, List<String>> _subjectsByGrade = {
    '12': [
      'Unit 1: Basic Concepts of ICT',
      'Unit 2: Introduction to Computer',
      'Unit 3: Data Representation',
      'Unit 4: Digital Circuits',
      'Unit 5: Operating Systems',
      'Unit 6: Data Communication & Networking',
      'Unit 7: System Analysis & Design',
      'Unit 8: Database Management',
    ],
    '13': [
      'Unit 9: Programming',
      'Unit 10: Web Development',
      'Unit 11: Internet of Things (IoT)',
      'Unit 12: ICT in Business',
      'Unit 13: New Trends in ICT',
    ],
  };

  final List<_GlobalChallengePaper> _papers = const [
    _GlobalChallengePaper(
      icon: Icons.auto_awesome,
      iconColors: [Color(0xFF2BD1F6), Color(0xFF9D58FF)],
      title: 'Paper 01 - SQL & DBMS',
      meta: 'Difficulty: Medium - Time: 1h 30m',
      attempts: 'Global attempts: 2,340',
    ),
    _GlobalChallengePaper(
      icon: Icons.psychology_alt_rounded,
      iconColors: [Color(0xFF5C77FF), Color(0xFFFF6DC8)],
      title: 'Paper 02 - Logic & Networks',
      meta: 'Difficulty: Hard - Time: 1h 45m',
      attempts: 'Global attempts: 1,720',
    ),
    _GlobalChallengePaper(
      icon: Icons.bolt_rounded,
      iconColors: [Color(0xFF4D5CFF), Color(0xFF8B63FF)],
      title: 'Paper 03 - System Analysis',
      meta: 'Difficulty: Easy - Time: 1h 15m',
      attempts: 'Global attempts: 3,010',
    ),
  ];

  String _selectedTab = 'Global';
  String _selectedExamType = 'Final Exam';
  String _selectedGrade = '13';
  String _selectedTerm = 'Term 1';
  String _selectedSubject = _subjectsByGrade['13']!.first;
  bool _isCreatingChallenge = false;

  bool get _isGlobal => _selectedTab == 'Global';
  bool get _requiresGrade => _selectedExamType != 'Final Exam';
  bool get _requiresTerm => _selectedExamType == 'Term Exam';
  bool get _requiresSubject => _selectedExamType == 'Subject Wise';
  List<String> get _availableSubjects =>
      _subjectsByGrade[_selectedGrade] ?? const [];

  @override
  void dispose() {
    _challengeNameController.dispose();
    super.dispose();
  }

  void _onExamTypeChanged(String value) {
    setState(() {
      _selectedExamType = value;
      if (_requiresSubject &&
          !_availableSubjects.contains(_selectedSubject) &&
          _availableSubjects.isNotEmpty) {
        _selectedSubject = _availableSubjects.first;
      }
    });
  }

  void _onGradeChanged(String value) {
    setState(() {
      _selectedGrade = value;
      if (_availableSubjects.isNotEmpty) {
        _selectedSubject = _availableSubjects.first;
      }
    });
  }

  Future<void> _createFriendChallenge() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before creating a challenge.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String paperType;
    switch (_selectedExamType) {
      case 'Term Exam':
        paperType = 'Term';
        break;
      case 'Subject Wise':
        paperType = 'Subject';
        break;
      default:
        paperType = 'Final';
    }

    final payload = <String, dynamic>{
      'host_user_id': currentUser.uid,
      'title': _challengeNameController.text.trim().isEmpty
          ? _defaultChallengeTitle()
          : _challengeNameController.text.trim(),
      'duration_seconds': 7200,
      'question_count': 50,
      'paper_type': paperType,
      'difficulty': 'Medium',
    };

    if (_requiresGrade) {
      payload['grade'] = _selectedGrade;
    }
    if (_requiresTerm) {
      payload['term'] = _selectedTerm;
    }
    if (_requiresSubject) {
      payload['topic'] = _selectedSubject;
    }

    setState(() => _isCreatingChallenge = true);

    try {
      final uri = Uri.parse('http://10.0.2.2:8000/friend-challenges');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.body);
      }

      final challengeData = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FriendChallengeLobbyScreen(
            challengeData: challengeData,
            currentUserId: currentUser.uid,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create challenge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingChallenge = false);
      }
    }
  }

  String _defaultChallengeTitle() {
    if (_selectedExamType == 'Final Exam') {
      return 'Final Exam Challenge';
    }
    if (_selectedExamType == 'Term Exam') {
      return 'Grade $_selectedGrade - $_selectedTerm Challenge';
    }
    return 'Grade $_selectedGrade - Subject Challenge';
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.sora(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.05,
    );

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
        child: Stack(
          children: [
            Positioned(
              top: 180,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF51D5FF).withValues(alpha: 0.26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -120,
              bottom: -80,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 320,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2AC7F4).withValues(alpha: 0.24),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isGlobal
                                    ? 'Active Challenge'
                                    : 'Activity Challenges',
                                style: titleStyle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isGlobal
                                    ? '3 papers every week - compete global with friends'
                                    : 'Create a challenge paper with your own filters',
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
                    const SizedBox(height: 22),
                    _SegmentedSelector(
                      options: const ['Global', 'Friends'],
                      selected: _selectedTab,
                      onChanged: (value) {
                        setState(() => _selectedTab = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isGlobal
                          ? _buildGlobalSection()
                          : _buildFriendsSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSection() {
    return Column(
      key: const ValueKey('global-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Season ends in',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7E87A7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2d 14h 08m',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _MiniPillButton(label: 'Generate / Refresh', onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "This Week's Challenge Papers",
          style: GoogleFonts.inter(
            color: const Color(0xFFB9C2E6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._papers.map(
          (paper) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GlobalPaperCard(paper: paper),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Friends Competitive Mode',
          style: GoogleFonts.inter(
            color: const Color(0xFFB9C2E6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AvatarCluster(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start a Friend Challenge',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a filtered paper and invite friends privately.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF95A0C3),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start sync for everyone can be tightened after the base flow works.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF68D8FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _MiniPillButton(
                        label: 'Create Friend Challenge',
                        onTap: () {
                          setState(() => _selectedTab = 'Friends');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection() {
    final labelStyle = GoogleFonts.inter(
      color: const Color(0xFFC4CBF6),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      fontStyle: FontStyle.italic,
    );

    return _GlassPanel(
      key: const ValueKey('friends-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Exam Type', style: labelStyle),
          const SizedBox(height: 8),
          _DropdownField(
            key: ValueKey('exam-type-$_selectedExamType'),
            value: _selectedExamType,
            items: _examTypes,
            onChanged: (value) {
              if (value == null) return;
              _onExamTypeChanged(value);
            },
          ),
          if (_requiresGrade) ...[
            const SizedBox(height: 14),
            Text('Select Grade', style: labelStyle),
            const SizedBox(height: 8),
            _DropdownField(
              key: ValueKey('grade-$_selectedGrade-$_selectedExamType'),
              value: 'Grade $_selectedGrade',
              items: _grades.map((g) => 'Grade $g').toList(),
              onChanged: (value) {
                if (value == null) return;
                _onGradeChanged(value.replaceAll('Grade ', ''));
              },
            ),
          ],
          if (_requiresTerm) ...[
            const SizedBox(height: 14),
            Text('Select Term', style: labelStyle),
            const SizedBox(height: 8),
            _DropdownField(
              key: ValueKey('term-$_selectedTerm-$_selectedGrade'),
              value: _selectedTerm,
              items: _terms,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedTerm = value);
              },
            ),
          ],
          if (_requiresSubject) ...[
            const SizedBox(height: 14),
            Text('Select Subject', style: labelStyle),
            const SizedBox(height: 8),
            _DropdownField(
              key: ValueKey(
                'subject-$_selectedGrade-$_selectedSubject-$_selectedExamType',
              ),
              value: _selectedSubject,
              items: _availableSubjects,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSubject = value);
              },
            ),
          ],
          const SizedBox(height: 14),
          Text('Challenge Name (Optional)', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _challengeNameController,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: _fieldDecoration(
              hintText: 'e.g., Weekend Study Sprint',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101528),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A3351)),
            ),
            child: Text(
              _selectedExamType == 'Final Exam'
                  ? 'This will generate a final challenge paper covering the full syllabus.'
                  : _selectedExamType == 'Term Exam'
                  ? 'This will generate a grade-specific term challenge paper.'
                  : 'This will generate a subject-wise challenge paper for the selected grade.',
              style: GoogleFonts.inter(
                color: const Color(0xFFDCE1FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: _isCreatingChallenge
                ? 'Creating Challenge...'
                : 'Start Challenge',
            onTap: _isCreatingChallenge ? null : _createFriendChallenge,
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: GoogleFonts.inter(
      color: const Color(0xFF7380A7),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: const Color(0xFF101528),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2A3351)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5C84FF), width: 1.2),
    ),
  );
}

class _GlobalChallengePaper {
  const _GlobalChallengePaper({
    required this.icon,
    required this.iconColors,
    required this.title,
    required this.meta,
    required this.attempts,
  });

  final IconData icon;
  final List<Color> iconColors;
  final String title;
  final String meta;
  final String attempts;
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 16, 14, 10),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1325).withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF323B64)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.36),
                blurRadius: 24,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}

class _SegmentedSelector extends StatelessWidget {
  const _SegmentedSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1325),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF313A63)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: options.map((option) {
          final active = option == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(option),
                  borderRadius: BorderRadius.circular(18),
                  splashColor: const Color(0xFF89D4FF).withValues(alpha: 0.18),
                  highlightColor: Colors.white.withValues(alpha: 0.04),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFF2FD2F8), Color(0xFFAA59FF)],
                            )
                          : null,
                      color: active ? null : const Color(0xFF131A31),
                      border: Border.all(
                        color: active
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFF202949),
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF64C8FF,
                                ).withValues(alpha: 0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          color: active
                              ? Colors.white
                              : const Color(0xFF9EA8CD),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF101528),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white54,
      ),
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(hintText: ''),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
    );
  }
}

class _GlobalPaperCard extends StatelessWidget {
  const _GlobalPaperCard({required this.paper});

  final _GlobalChallengePaper paper;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: paper.iconColors),
            ),
            child: Icon(paper.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper.title,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paper.meta,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB4BFDF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  paper.attempts,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF68D8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _MiniPillButton(label: 'Attempt', onTap: () {}),
        ],
      ),
    );
  }
}

class _AvatarCluster extends StatelessWidget {
  const _AvatarCluster();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _AvatarBubble(icon: Icons.person_outline_rounded),
        SizedBox(width: 8),
        _AvatarBubble(icon: Icons.person_outline_rounded),
      ],
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2FD2F8), Color(0xFFAA59FF)],
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF101528),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF8FA0CF)),
      ),
    );
  }
}

class _MiniPillButton extends StatelessWidget {
  const _MiniPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withValues(alpha: 0.12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF2FD2F8), Color(0xFFAA59FF)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58C5FF).withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: onTap == null
                ? const LinearGradient(
                    colors: [Color(0xFF343C56), Color(0xFF242B41)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF28D0F4), Color(0xFFAA5BFF)],
                  ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF55BDFD,
                ).withValues(alpha: onTap == null ? 0.08 : 0.26),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
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
    );
  }
}

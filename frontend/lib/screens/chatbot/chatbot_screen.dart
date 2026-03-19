import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/models/chat_message.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      role: "assistant",
      text:
          'Hi! I can search past papers,\nexplain ICT concepts recommend papers.',
    ),
    ChatMessage(role: "user", text: 'Show SQL normalization past paper essays'),
    ChatMessage(
      role: "assistant",
      text:
          'I found 6 essay questions on Normalization:\n'
          '• 2022 A/L Paper Q4\n'
          '• 2021 Model Paper 2 Q3\n'
          '• 2019 Past Paper Q5',
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final ChatService _chatService = ChatService();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  bool _isListening = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _onSpeechResult(dynamic result) {
    setState(() {
      _controller.text = result.recognizedWords;
      // Move cursor to end
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  Future<void> _startListening() async {
    // Request permission if not already granted
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize();
    }

    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendText([String? forcedText]) async {
    final text = (forcedText ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: "user", text: text));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Call backend
    final responseMsg = await _chatService.sendMessage(text);

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(responseMsg);
    });
    _scrollToBottom();
  }

  void _useSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _focus.requestFocus();
    _sendText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png.png'),
            fit: BoxFit.cover,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                _TopBar(
                  title: 'Brainex AI Chatbot',
                  subtitle: 'Smart past-paper syllabus assistant',
                  onBack: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 14),

                /// CHAT LIST
                Expanded(
                  child: GlassCard(
                    radius: 22,
                    blur: 40,
                    borderOpacity: 0.30,
                    animateSheen: true,
                    addInnerGlow: true,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      children: [
                        const _AskAnythingCard(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.only(bottom: 10),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isTyping && index == _messages.length) {
                                return const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: _TypingBubble(),
                                  ),
                                );
                              }

                              final msg = _messages[index];
                              final isUser = msg.role == "user";

                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: AnimatedMessage(
                                  isUser: isUser,
                                  child: isUser
                                      ? _UserPill(text: msg.text)
                                      : _MessageCard(
                                          header: 'Brainex AI',
                                          body: msg.text,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),
                        const Text(
                          'Quick Suggestions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _SuggestionChip(
                                text: 'Find Logic Gate MCQs',
                                onTap: () =>
                                    _useSuggestion('Find Logic Gate MCQs'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SuggestionChip(
                                text: 'Explain OSI Model',
                                onTap: () =>
                                    _useSuggestion('Explain OSI Model'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _SuggestionChip(
                                text: 'Show SQL JOIN past papers',
                                onTap: () =>
                                    _useSuggestion('Show SQL JOIN past papers'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SuggestionChip(
                                text: 'Give me a plan',
                                onTap: () => _useSuggestion('Give me a plan'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _OutlinePillButton(
                                text: 'View Papers',
                                onTap: () => _useSuggestion(
                                  'View papers for this topic',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OutlinePillButton(
                                text: 'Get Short Notes',
                                onTap: () => _useSuggestion(
                                  'Give short notes for this topic',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _GradientPillButton(
                                text: 'Start Quiz',
                                onTap: () => _useSuggestion('Start a quiz'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                _InputBar(
                  controller: _controller,
                  focusNode: _focus,
                  onSend: _sendText,
                  isTyping: _isTyping,
                  isListening: _isListening,
                  onMicTap: _toggleListening,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- ANIMATION WRAPPER ----------------
/// Pop-in + fade + slide for every new message widget.
class AnimatedMessage extends StatefulWidget {
  final Widget child;
  final bool isUser;

  const AnimatedMessage({super.key, required this.child, required this.isUser});

  @override
  State<AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.97,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

    final dx = widget.isUser ? 0.03 : -0.03;
    _slide = Tween<Offset>(
      begin: Offset(dx, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// ---------------- PRESS ANIMATION ----------------
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() => _c.forward();
  void _up() => _c.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapCancel: _up,
      onTapUp: (_) => _up(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.scale(scale: _s.value, child: widget.child),
      ),
    );
  }
}

/// ---------------- TYPING INDICATOR (PULSE + DOTS) ----------------
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _s = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _s,
      child: GlassCard(
        radius: 18,
        blur: 100,
        borderOpacity: 0.18,
        animateSheen: true,
        addInnerGlow: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(delayMs: 0),
            SizedBox(width: 6),
            _Dot(delayMs: 120),
            SizedBox(width: 6),
            _Dot(delayMs: 240),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delayMs;
  const _Dot({required this.delayMs});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _y;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _y = Tween<double>(
      begin: 0,
      end: -5,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}

/// ---------------- UI PARTS (UPDATED) ----------------

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.white,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------- GLASS CARD (STRONGER + SHEEN) ----------------
class GlassCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// More glass controls
  final double blur;
  final double borderOpacity;
  final bool animateSheen;
  final bool addInnerGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(14),
    this.blur = 22,
    this.borderOpacity = 0.16,
    this.animateSheen = true,
    this.addInnerGlow = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animateSheen) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant GlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateSheen && !_c.isAnimating) _c.repeat();
    if (!widget.animateSheen && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            final sheenX = -1.2 + (2.4 * t);

            return Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Inner glow
                  if (widget.addInnerGlow)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: r,
                            gradient: RadialGradient(
                              center: const Alignment(-0.6, -0.8),
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Sheen shimmer
                  if (widget.animateSheen)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Transform.translate(
                          offset: Offset(sheenX * 220, 0),
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Top highlight line
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),

                  widget.child,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AskAnythingCard extends StatelessWidget {
  const _AskAnythingCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      blur: 26,
      borderOpacity: 0.18,
      animateSheen: true,
      addInnerGlow: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF55D6FF).withValues(alpha: 0.3),
                  const Color(0xFF8A5CFF).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask anything about A/L ICT',
                  style: TextStyle(fontSize: 12.8, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Example: "Find past paper SQL JOIN questions"',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String header;
  final String body;

  const _MessageCard({required this.header, required this.body});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassCard(
        radius: 18,
        blur: 26,
        borderOpacity: 0.18,
        animateSheen: true,
        addInnerGlow: true,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            MarkdownBody(
              data: body,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 11.6,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
                listBullet: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  final String text;
  const _UserPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GlassCard(
        radius: 18,
        blur: 24,
        borderOpacity: 0.16,
        animateSheen: true,
        addInnerGlow: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 11.6,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _OutlinePillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.965,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.2,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GradientPillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.965,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF55D6FF).withValues(alpha: 0.8),
              const Color(0xFF8A5CFF).withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Start Quiz',
            style: TextStyle(
              fontSize: 11.2,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.0,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// UPDATED: real input + send action + disabled while typing
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<void> Function() onSend;
  final bool isTyping;
  final bool isListening;
  final VoidCallback onMicTap;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isTyping,
    required this.isListening,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      blur: 26,
      borderOpacity: 0.18,
      animateSheen: true,
      addInnerGlow: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Mic + Wave animation (Row)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onMicTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isListening
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none_rounded,
                    size: 16,
                    color: isListening ? Colors.redAccent : Colors.white70,
                  ),
                ),
              ),

              // Animated wave appears only while listening
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isListening
                    ? Padding(
                        key: const ValueKey('wave'),
                        padding: const EdgeInsets.only(left: 8),
                        child: MicWave(
                          active: true,
                          height: 18,
                          width: 40,
                          bars: 6,
                          color: Colors.redAccent,
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('nowave'),
                        width: 0,
                        height: 18,
                      ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isTyping,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              cursorColor: Colors.white70,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Ask Brainex AI anything...',
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),

          // Send button (pressable)
          Opacity(
            opacity: isTyping ? 0.5 : 1,
            child: PressableScale(
              onTap: isTyping ? () {} : () => onSend(),
              pressedScale: 0.94,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF55D6FF).withValues(alpha: 0.9),
                      const Color(0xFF8A5CFF).withValues(alpha: 0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------- MIC WAVE ANIMATION ----------------
class MicWave extends StatefulWidget {
  final bool active;
  final double height;
  final double width;
  final int bars;
  final Color color;

  const MicWave({
    super.key,
    required this.active,
    this.height = 18,
    this.width = 38,
    this.bars = 6,
    this.color = Colors.redAccent,
  });

  @override
  State<MicWave> createState() => _MicWaveState();
}

class _MicWaveState extends State<MicWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant MicWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _barValue(double t, int i) {
    // Different phase per bar => "moving" look
    final phase = i * 0.55;
    final v = (sin((t * 2 * pi) + phase) + 1) / 2; // 0..1
    // keep some minimum height so it never disappears
    return 0.25 + (v * 0.75); // 0.25..1.0
  }

  @override
  Widget build(BuildContext context) {
    final barW = (widget.width / (widget.bars * 1.8)).clamp(2.0, 5.0);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.bars, (i) {
              final h = widget.height * _barValue(_c.value, i);

              return Container(
                width: barW,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: widget.color.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

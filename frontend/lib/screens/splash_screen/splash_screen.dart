import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:frontend/screens/wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  int dotCount = 0;
  Timer? timer;

  // Animation Controllers
  late AnimationController _drawController;
  late AnimationController _flickerController;
  late AnimationController _arcController;

  @override
  void initState() {
    super.initState();

    // 1. Outer Circle Draw Animation (2 seconds)
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 2. Neon Flicker Animation (Looping)
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // 3. Electric Arc Animation (Looping)
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); // Re-randomizes on every frame due to painter logic or verify listener

    // Start the draw animation
    _drawController.forward();

    // Loading dots animation
    timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        dotCount = (dotCount + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _drawController.dispose();
    _flickerController.dispose();
    _arcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/Splash_Screen_BG.png',
              fit: BoxFit.cover,
            ),
          ),

          // 🔹 CONTENT
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ANIMATED LOGO
                SizedBox(
                  height: 160, // Slightly larger to accommodate glow/arcs
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Outer Circle & Glow
                      AnimatedBuilder(
                        animation: _drawController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(140, 140),
                            painter: _OuterCirclePainter(
                              progress: _drawController.value,
                              color: const Color(0xFF00A2FF),
                              glowIntensity: 10.0, // High glow
                            ),
                          );
                        },
                      ),

                      // 2. Electric Arc (Border)
                      AnimatedBuilder(
                        animation: _arcController,
                        builder: (context, child) {
                          // Only show arcs after circle starts drawing
                          if (_drawController.value < 0.2) {
                            return const SizedBox();
                          }
                          return CustomPaint(
                            size: const Size(140, 140),
                            painter: _ElectricArcPainter(
                              color: const Color(0xFF00E5FF),
                              seed: _arcController.value, // Drive randomization
                            ),
                          );
                        },
                      ),

                      // 3. Inner Logo (Brain + X + Blob)
                      // Using existing asset with flicker effect
                      AnimatedBuilder(
                        animation: _flickerController,
                        builder: (context, child) {
                          // Flicker opacity between 0.8 and 1.0
                          // Randomize slightly for "neon" feel
                          final flickerVal = _flickerController.value;
                          final opacity = 0.8 + (flickerVal * 0.2);

                          return Opacity(
                            opacity: opacity,
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 100, // Inner size
                              width: 100,
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // APP NAME
                const Text(
                  'BraineX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                // TAGLINE
                const Text(
                  'Upload • Scan • Improve',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 60),

                // LOADING TEXT
                Text(
                  'Getting things ready${"." * dotCount}',
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAINTERS
// -----------------------------------------------------------------------------

class _OuterCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;

  _OuterCirclePainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 10; // Margin for glow
    final rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Add Glow
    if (glowIntensity > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.solid, glowIntensity);
    }

    // Draw full path up to progress
    // Start from top (-pi/2)
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Optional: Add a second pass without blur for a sharp core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, corePaint);
  }

  @override
  bool shouldRepaint(_OuterCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class _ElectricArcPainter extends CustomPainter {
  final Color color;
  final double seed; // Changes to force randomization

  _ElectricArcPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 10;
    final random = math.Random();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      // Glow for arc
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    // Generate 2-3 random arcs along the circle
    final numArcs = random.nextInt(2) + 2;

    for (int i = 0; i < numArcs; i++) {
      // Random start angle
      final startAngle = random.nextDouble() * 2 * math.pi;
      // Random length
      final sweepAngle = (random.nextDouble() * 0.5) + 0.2; // 0.2 to 0.7 rads

      // Create a path for this arc but jitter it
      final path = Path();
      final points = <Offset>[];
      final steps = 10;

      for (int j = 0; j <= steps; j++) {
        final t = j / steps;
        final currentAngle = startAngle + (sweepAngle * t);

        // Jitter radius
        final rJitter = (random.nextDouble() - 0.5) * 10; // +/- 5px deviation
        final r = radius + rJitter;

        final x = center.dx + r * math.cos(currentAngle);
        final y = center.dy + r * math.sin(currentAngle);
        points.add(Offset(x, y));
      }

      path.addPolygon(points, false);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ElectricArcPainter oldDelegate) {
    // Repaint every time seed changes (which is every frame)
    return oldDelegate.seed != seed;
  }
}

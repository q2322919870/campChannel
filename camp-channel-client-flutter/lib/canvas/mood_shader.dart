import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ported from PC client's MoodShaderEffect.ts (Three.js shader).
/// Provides breathing glass and glitch effects for card widgets.
enum MoodMode { glass, glitch }

class MoodShaderPainter extends CustomPainter {
  final double time;
  final Color primary;
  final Color accent;
  final Color glowColor;
  final double intensity;
  final MoodMode mode;

  MoodShaderPainter({
    required this.time,
    required this.primary,
    required this.accent,
    required this.glowColor,
    this.intensity = 0.3,
    this.mode = MoodMode.glass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time;

    if (mode == MoodMode.glass) {
      _paintGlass(canvas, w, h, t);
    } else {
      _paintGlitch(canvas, w, h, t);
    }
  }

  void _paintGlass(Canvas canvas, double w, double h, double t) {
    // Breathing effect
    final breathe = math.sin(t * 1.5) * 0.15 + 0.15;
    final alpha = breathe * intensity * 0.4;

    // Animated color blend
    final blendRatio = math.sin(t * 0.5) * 0.3 + 0.5;
    final blendedColor = Color.fromARGB(
      (alpha * 255).round().clamp(0, 255),
      (primary.red + (accent.red - primary.red) * blendRatio).round().clamp(0, 255),
      (primary.green + (accent.green - primary.green) * blendRatio).round().clamp(0, 255),
      (primary.blue + (accent.blue - primary.blue) * blendRatio).round().clamp(0, 255),
    );

    // Ripple from center
    final cx = w / 2;
    final cy = h / 2;
    final maxR = math.sqrt(w * w + h * h) / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          blendedColor,
          glowColor.withOpacity(alpha * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    // Wave overlay
    final waveAlpha = (math.sin(t * 2.0) * 0.05 + 0.05) * intensity;
    final wavePaint = Paint()
      ..color = glowColor.withOpacity(waveAlpha.clamp(0.0, 0.15));
    for (double y = 0; y < h; y += 4) {
      final waveOffset = math.sin(y * 0.05 + t) * 3;
      canvas.drawRect(
        Rect.fromLTWH(waveOffset, y, w, 2),
        wavePaint,
      );
    }
  }

  void _paintGlitch(Canvas canvas, double w, double h, double t) {
    // Glitch scanlines
    final random = math.Random((t * 10).floor());
    final glitchIntensity = random.nextDouble() > 0.97 ? 1.0 : 0.0;

    if (glitchIntensity > 0) {
      // Horizontal glitch bars
      for (int i = 0; i < 5; i++) {
        final y = random.nextDouble() * h;
        final barH = 2 + random.nextDouble() * 8;
        final shift = (random.nextDouble() - 0.5) * 20;
        final barPaint = Paint()
          ..color = primary.withOpacity(0.15 + random.nextDouble() * 0.1);
        canvas.drawRect(
          Rect.fromLTWH(shift, y, w, barH),
          barPaint,
        );
      }

      // Color shift overlay
      final shiftPaint = Paint()
        ..color = glowColor.withOpacity(0.08);
      canvas.drawRect(
        Rect.fromLTWH(random.nextDouble() * 4 - 2, 0, w, h),
        shiftPaint,
      );
    }

    // Subtle scanlines
    final scanPaint = Paint()..color = Colors.black.withOpacity(0.03);
    for (double y = 0; y < h; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1), scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MoodShaderPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.intensity != intensity;
}

/// Widget wrapper that adds a shader effect overlay to any card.
/// Ported from PC client's ShaderPostCard.vue.
class ShaderCard extends StatefulWidget {
  final Widget child;
  final MoodMode mood;
  final double intensity;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? glowColor;

  const ShaderCard({
    super.key,
    required this.child,
    this.mood = MoodMode.glass,
    this.intensity = 0.2,
    this.primaryColor,
    this.accentColor,
    this.glowColor,
  });

  @override
  State<ShaderCard> createState() => _ShaderCardState();
}

class _ShaderCardState extends State<ShaderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _currentIntensity = 0.2;

  @override
  void initState() {
    super.initState();
    _currentIntensity = widget.intensity;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.primaryColor ?? theme.colorScheme.primary;
    final accent = widget.accentColor ?? theme.colorScheme.secondary;
    final glow = widget.glowColor ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background shader overlay - positioned to fill stack without expanding
              Positioned.fill(
                child: CustomPaint(
                  painter: MoodShaderPainter(
                    time: _controller.value * 60.0,
                    primary: primary,
                    accent: accent,
                    glowColor: glow,
                    intensity: _currentIntensity,
                    mode: widget.mood,
                  ),
                ),
              ),
              // Foreground content - determines the stack's size
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

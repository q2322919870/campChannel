import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Time-of-day periods for environment effects.
enum TimePeriod { morning, afternoon, evening, night }

/// Determines current time period.
TimePeriod getCurrentTimePeriod() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return TimePeriod.morning;
  if (hour >= 12 && hour < 17) return TimePeriod.afternoon;
  if (hour >= 17 && hour < 20) return TimePeriod.evening;
  return TimePeriod.night;
}

/// Returns a tint color based on current time period.
Color getTimePeriodTint(TimePeriod period) {
  switch (period) {
    case TimePeriod.morning:
      return const Color(0xFFFFD700).withOpacity(0.06); // warm gold
    case TimePeriod.afternoon:
      return Colors.transparent; // clear
    case TimePeriod.evening:
      return const Color(0xFFFF6B35).withOpacity(0.08); // orange sunset
    case TimePeriod.night:
      return const Color(0xFF4A00E0).withOpacity(0.1); // deep neon
  }
}

// ═══════════════════════════════════════════════
// Rain Drop Painter - animated raindrops sliding down
// ═══════════════════════════════════════════════
class RainDropPainter extends CustomPainter {
  final double time;
  final Color color;
  final int dropCount;
  final math.Random _rng = math.Random(42);

  RainDropPainter({
    required this.time,
    this.color = const Color(0xFF87CEEB),
    this.dropCount = 30,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < dropCount; i++) {
      final x = _rng.nextDouble() * w;
      final speed = 80 + _rng.nextDouble() * 120;
      final length = 8 + _rng.nextDouble() * 16;
      final y = ((time * speed + i * 37) % (h + length)) - length;
      final alpha = 0.15 + _rng.nextDouble() * 0.2;

      paint.color = color.withOpacity(alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 1, y + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RainDropPainter old) => old.time != time;
}

// ═══════════════════════════════════════════════
// Snow Flake Painter - gentle snowflakes
// ═══════════════════════════════════════════════
class SnowFlakePainter extends CustomPainter {
  final double time;
  final int flakeCount;
  final math.Random _rng = math.Random(99);

  SnowFlakePainter({required this.time, this.flakeCount = 25});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < flakeCount; i++) {
      final baseX = _rng.nextDouble() * w;
      final speed = 20 + _rng.nextDouble() * 30;
      final radius = 1.5 + _rng.nextDouble() * 3;
      final y = ((time * speed + i * 53) % (h + radius * 2)) - radius;
      final x = baseX + math.sin(time * 0.8 + i) * 20;
      final alpha = 0.2 + _rng.nextDouble() * 0.3;

      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(x % w, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SnowFlakePainter old) => old.time != time;
}

// ═══════════════════════════════════════════════
// Neon Glow Painter - neon edge glow for nighttime
// ═══════════════════════════════════════════════
class NeonGlowPainter extends CustomPainter {
  final double time;
  final Color primary;
  final Color secondary;

  NeonGlowPainter({
    required this.time,
    this.primary = const Color(0xFF6C63FF),
    this.secondary = const Color(0xFFFF6584),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time;

    // Pulsating edge glow
    final pulse = math.sin(t * 1.2) * 0.15 + 0.25;

    // Top edge glow
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 3),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(w, 0),
          [primary.withOpacity(pulse), secondary.withOpacity(pulse)],
        ),
    );

    // Side glows with blur
    final sideGlowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = primary.withOpacity(pulse * 0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, 2, h), sideGlowPaint);

    final sideGlowPaint2 = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..color = secondary.withOpacity(pulse * 0.3);
    canvas.drawRect(Rect.fromLTWH(w - 2, 0, 2, h), sideGlowPaint2);

    // Stars
    final rng = math.Random(77);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.3;
      final r = 0.5 + rng.nextDouble() * 1.5;
      final twinkle = math.sin(t * 2 + i * 1.5) * 0.3 + 0.4;
      starPaint.color = Colors.white.withOpacity(twinkle);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NeonGlowPainter old) => old.time != time;
}

/// Environment-responsive weather effect overlay widget.
class WeatherEffectsOverlay extends StatefulWidget {
  final TimePeriod period;

  const WeatherEffectsOverlay({super.key, required this.period});

  @override
  State<WeatherEffectsOverlay> createState() => _WeatherEffectsOverlayState();
}

class _WeatherEffectsOverlayState extends State<WeatherEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
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
    final period = widget.period;
    final tint = getTimePeriodTint(period);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 60.0;
          return Stack(
            children: [
              // Time period tint
              if (tint != Colors.transparent)
                Positioned.fill(
                  child: Container(color: tint),
                ),
              // Rain for evening/night (optional aesthetic)
              if (period == TimePeriod.night)
                Positioned.fill(
                  child: CustomPaint(
                    painter: RainDropPainter(
                      time: t,
                      color: const Color(0xFF6C63FF),
                      dropCount: 15,
                    ),
                  ),
                ),
              // Neon glow for night
              if (period == TimePeriod.night)
                Positioned.fill(
                  child: CustomPaint(
                    painter: NeonGlowPainter(time: t),
                  ),
                ),
              // Snow for morning in winter months (Dec-Feb)
              if (period == TimePeriod.morning &&
                  (DateTime.now().month >= 12 || DateTime.now().month <= 2))
                Positioned.fill(
                  child: CustomPaint(
                    painter: SnowFlakePainter(time: t),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

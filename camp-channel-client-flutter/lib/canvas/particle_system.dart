import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ported from PC client's CanvasEngine.ts (ParticleSystem + GlassEffect + ThemeRenderer).
/// Renders floating particles with connecting lines and mouse-repulsion effect.
class ParticleSystemPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset pointer;
  final Color glowColor;

  ParticleSystemPainter({
    required this.particles,
    required this.pointer,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Draw particles
    for (final p in particles) {
      final alpha = p.alpha * (0.8 + 0.2 * math.sin(p.pulse + time));
      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }

    // Draw connecting lines
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < 150) {
          final alpha = (1 - dist / 150) * 0.15;
          final linePaint = Paint()
            ..color = Colors.white.withOpacity(alpha)
            ..strokeWidth = 0.5;
          canvas.drawLine(
            Offset(particles[i].x, particles[i].y),
            Offset(particles[j].x, particles[j].y),
            linePaint,
          );
        }
      }
    }

    // Glass effect: glow around pointer
    if (pointer != Offset.zero) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          pointer,
          300,
          [glowColor.withOpacity(0.12), Colors.transparent],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
    }

    // Secondary glow spots
    final g1 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.8, size.height * 0.15),
        400,
        [glowColor.withOpacity(0.06), Colors.transparent],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), g1);

    final g2 = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.2, size.height * 0.85),
        350,
        [glowColor.withOpacity(0.05), Colors.transparent],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), g2);
  }

  @override
  bool shouldRepaint(covariant ParticleSystemPainter oldDelegate) => true;
}

class _Particle {
  double x, y, vx, vy, size, alpha, pulse;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.alpha,
    required this.pulse,
  });
}

/// Manages particle state and physics simulation.
class ParticleSystemController {
  final List<_Particle> particles = [];
  final int count;
  final math.Random _random = math.Random();

  ParticleSystemController({this.count = 60});

  void init(double width, double height) {
    particles.clear();
    for (int i = 0; i < count; i++) {
      particles.add(_createParticle(width, height));
    }
  }

  _Particle _createParticle(double width, double height) {
    return _Particle(
      x: _random.nextDouble() * width,
      y: _random.nextDouble() * height,
      vx: (_random.nextDouble() - 0.5) * 0.5,
      vy: (_random.nextDouble() - 0.5) * 0.5,
      size: _random.nextDouble() * 2 + 1,
      alpha: _random.nextDouble() * 0.5 + 0.1,
      pulse: _random.nextDouble() * math.pi * 2,
    );
  }

  void update(double width, double height, double mouseX, double mouseY) {
    for (final p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.pulse += 0.02;

      // Mouse repulsion
      final dx = p.x - mouseX;
      final dy = p.y - mouseY;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < 100 && dist > 0) {
        p.x += dx / dist * 0.3;
        p.y += dy / dist * 0.3;
      }

      if (p.x < 0 || p.x > width) p.vx *= -1;
      if (p.y < 0 || p.y > height) p.vy *= -1;
    }
  }
}

/// Widget that drives the particle system with a ticker.
class ParticleSystemWidget extends StatefulWidget {
  final Color glowColor;
  final int particleCount;

  const ParticleSystemWidget({
    super.key,
    required this.glowColor,
    this.particleCount = 60,
  });

  @override
  State<ParticleSystemWidget> createState() => _ParticleSystemWidgetState();
}

class _ParticleSystemWidgetState extends State<ParticleSystemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ParticleSystemController _system;
  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();
    _system = ParticleSystemController(count: widget.particleCount);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_system.particles.isEmpty) {
          _system.init(constraints.maxWidth, constraints.maxHeight);
        }
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    _system.update(
                      constraints.maxWidth,
                      constraints.maxHeight,
                      _pointer.dx,
                      _pointer.dy,
                    );
                    return CustomPaint(
                      painter: ParticleSystemPainter(
                        particles: _system.particles,
                        pointer: _pointer,
                        glowColor: widget.glowColor,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) =>
                    setState(() => _pointer = details.localPosition),
                onPanEnd: (_) => setState(() => _pointer = Offset.zero),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

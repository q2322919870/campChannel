import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ported from PC client's ParticleBurst.ts.
/// A burst particle effect with gravity and decay, triggered on events like "like" clicks.
class ParticleBurstPainter extends CustomPainter {
  final List<BurstParticle> particles;

  ParticleBurstPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = p.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 2);
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticleBurstPainter oldDelegate) => true;
}

class BurstParticle {
  double x, y, vx, vy, life, decay, size;
  Color color;
  double gravity;

  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.decay,
    required this.size,
    required this.color,
    required this.gravity,
  });
}

/// Controller that manages burst particle lifecycle.
class ParticleBurstController {
  final List<BurstParticle> particles = [];
  final math.Random _random = math.Random();
  bool _running = false;

  bool get isRunning => _running;
  bool get hasParticles => particles.isNotEmpty;

  void burst({
    required double x,
    required double y,
    int count = 60,
    Color color = const Color(0xFF7C9FCB),
  }) {
    for (int i = 0; i < count; i++) {
      final angle = (math.pi * 2 * i) / count + (_random.nextDouble() - 0.5) * 0.3;
      final speed = 4 + _random.nextDouble() * 8;
      particles.add(BurstParticle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: 1.0,
        decay: 0.008 + _random.nextDouble() * 0.015,
        size: 3 + _random.nextDouble() * 6,
        color: color,
        gravity: 0.05,
      ));
    }
    _running = true;
  }

  /// Call each frame to update particle physics.
  void update() {
    particles.removeWhere((p) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += p.gravity;
      p.vx *= 0.98;
      p.vy *= 0.98;
      p.life -= p.decay;
      return p.life <= 0;
    });
    if (particles.isEmpty) _running = false;
  }

  void clear() {
    particles.clear();
    _running = false;
  }
}

/// Overlay widget for particle burst effects. Place this as the top-most
/// widget in a Stack so it renders above all content.
class ParticleBurstOverlay extends StatefulWidget {
  final ParticleBurstController controller;

  const ParticleBurstOverlay({super.key, required this.controller});

  @override
  State<ParticleBurstOverlay> createState() => ParticleBurstOverlayState();
}

class ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (widget.controller.hasParticles) {
            _animController.forward(from: 0);
          }
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          widget.controller.update();
          return CustomPaint(
            painter: ParticleBurstPainter(particles: widget.controller.particles),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  /// Call this to trigger a burst and start the animation loop.
  void triggerBurst(double x, double y, {Color? color}) {
    widget.controller.burst(
      x: x,
      y: y,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
    _animController.forward(from: 0);
  }
}

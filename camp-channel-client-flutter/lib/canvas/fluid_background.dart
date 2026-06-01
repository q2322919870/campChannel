import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Ported from PC client's FluidBackground.ts (Three.js WebGL shader).
/// Renders an animated fluid-like gradient background using CustomPainter.
/// Features: flowing sine-wave color blends, mouse/touch influence, vignette.
class FluidBackgroundPainter extends CustomPainter {
  final double time;
  final Offset pointer;
  final Color primary;
  final Color accent;
  final Color glowColor;

  FluidBackgroundPainter({
    required this.time,
    required this.pointer,
    required this.primary,
    required this.accent,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time * 0.15;

    // Base gradient background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(w, h),
        [
          _blendColors(primary, accent, 0.0),
          _blendColors(primary, accent, 0.5),
          _blendColors(primary, accent, 1.0),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Fluid blobs using radial gradients with sine-wave animation
    _drawFluidBlob(
      canvas, w, h,
      cx: w * (0.3 + 0.15 * math.sin(t * 1.2)),
      cy: h * (0.25 + 0.1 * math.cos(t * 0.9)),
      radius: w * 0.45,
      color: primary,
      alpha: 0.18,
    );

    _drawFluidBlob(
      canvas, w, h,
      cx: w * (0.7 + 0.1 * math.cos(t * 0.8 + 1.5)),
      cy: h * (0.6 + 0.15 * math.sin(t * 1.1 + 0.8)),
      radius: w * 0.5,
      color: accent,
      alpha: 0.15,
    );

    _drawFluidBlob(
      canvas, w, h,
      cx: w * (0.5 + 0.2 * math.sin(t * 0.6 + 2.5)),
      cy: h * (0.8 + 0.08 * math.cos(t * 1.3 + 1.2)),
      radius: w * 0.35,
      color: glowColor,
      alpha: 0.12,
    );

    // Mouse/touch influence glow
    if (pointer != Offset.zero) {
      _drawFluidBlob(
        canvas, w, h,
        cx: pointer.dx,
        cy: pointer.dy,
        radius: 250,
        color: glowColor,
        alpha: 0.12,
      );
    }

    // Pulse glow
    final pulse = math.sin(t * 2.0) * 0.04 + 0.04;
    _drawFluidBlob(
      canvas, w, h,
      cx: w * 0.5,
      cy: h * 0.5,
      radius: w * 0.8,
      color: glowColor,
      alpha: pulse,
    );

    // Vignette overlay
    final vignettePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(w / 2, h / 2),
        w * 0.7,
        [
          Colors.transparent,
          Colors.black.withOpacity(0.3),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), vignettePaint);
  }

  void _drawFluidBlob(Canvas canvas, double w, double h, {
    required double cx,
    required double cy,
    required double radius,
    required Color color,
    required double alpha,
  }) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius,
        [
          color.withOpacity(alpha),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
  }

  Color _blendColors(Color c1, Color c2, double ratio) {
    return Color.fromARGB(
      255,
      (c1.red + (c2.red - c1.red) * ratio).round(),
      (c1.green + (c2.green - c1.green) * ratio).round(),
      (c1.blue + (c2.blue - c1.blue) * ratio).round(),
    );
  }

  @override
  bool shouldRepaint(covariant FluidBackgroundPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.pointer != pointer;
}

/// Widget wrapper that drives the FluidBackgroundPainter with an AnimationController.
class FluidBackground extends StatefulWidget {
  final Color primary;
  final Color accent;
  final Color glowColor;

  const FluidBackground({
    super.key,
    required this.primary,
    required this.accent,
    required this.glowColor,
  });

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pointer = Offset.zero;

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
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: FluidBackgroundPainter(
                time: _controller.value * 60.0,
                pointer: _pointer,
                primary: widget.primary,
                accent: widget.accent,
                glowColor: widget.glowColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Interactive version that tracks touch position for the glow effect.
class InteractiveFluidBackground extends StatefulWidget {
  final Color primary;
  final Color accent;
  final Color glowColor;
  final Widget child;

  const InteractiveFluidBackground({
    super.key,
    required this.primary,
    required this.accent,
    required this.glowColor,
    required this.child,
  });

  @override
  State<InteractiveFluidBackground> createState() =>
      _InteractiveFluidBackgroundState();
}

class _InteractiveFluidBackgroundState
    extends State<InteractiveFluidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pointer = Offset.zero;

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
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: FluidBackgroundPainter(
                    time: _controller.value * 60.0,
                    pointer: _pointer,
                    primary: widget.primary,
                    accent: widget.accent,
                    glowColor: widget.glowColor,
                  ),
                );
              },
            ),
          ),
        ),
        GestureDetector(
          onPanUpdate: (details) =>
              setState(() => _pointer = details.localPosition),
          onPanEnd: (_) => setState(() => _pointer = Offset.zero),
          child: widget.child,
        ),
      ],
    );
  }
}

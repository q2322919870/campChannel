import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Animated fog/mist shader painter.
/// Renders a misty overlay that can be "cleared" by touch/drag interaction.
/// Ported from PC client's mist-reveal canvas effect.
class FogShaderPainter extends CustomPainter {
  final double time;
  final Color fogColor;
  final Color accentColor;
  final Path clearPath;
  final double opacity;

  FogShaderPainter({
    required this.time,
    required this.fogColor,
    required this.accentColor,
    required this.clearPath,
    this.opacity = 0.85,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = time;
    final rng = math.Random(42);

    // If no clear path, draw full fog
    if (clearPath.getBounds().width == 0 || clearPath.getBounds().height == 0) {
      // Draw fog base layer - completely opaque
      final basePaint = Paint()
        ..color = fogColor.withOpacity(opacity);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

      // Draw animated mist swirls
      for (int i = 0; i < 6; i++) {
        final cx = (rng.nextDouble() * w + math.sin(t * 0.3 + i * 1.2) * 40) % w;
        final cy = (rng.nextDouble() * h + math.cos(t * 0.25 + i * 0.8) * 30) % h;
        final radius = 30.0 + rng.nextDouble() * 50;
        final swirlAlpha = 0.08 + math.sin(t * 0.5 + i) * 0.04;

        final swirlPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            radius,
            [
              accentColor.withOpacity(swirlAlpha),
              fogColor.withOpacity(swirlAlpha * 0.5),
              Colors.transparent,
            ],
            [0.0, 0.5, 1.0],
          );
        canvas.drawRect(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          swirlPaint,
        );
      }

      // Wavy horizontal mist bands
      for (double y = 0; y < h; y += 6) {
        final bandAlpha = (math.sin(y * 0.04 + t * 0.6) * 0.05 + 0.06) * opacity;
        final offsetX = math.sin(y * 0.02 + t * 0.4) * 8;
        final bandPaint = Paint()
          ..color = accentColor.withOpacity(bandAlpha.clamp(0.0, 0.15));
        canvas.drawRect(Rect.fromLTWH(offsetX, y, w, 3), bandPaint);
      }
      return;
    }

    // If there's a clear path, use a layer to composite properly
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    
    // Draw fog base layer - completely opaque
    final basePaint = Paint()
      ..color = fogColor.withOpacity(opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    // Draw animated mist swirls
    for (int i = 0; i < 6; i++) {
      final cx = (rng.nextDouble() * w + math.sin(t * 0.3 + i * 1.2) * 40) % w;
      final cy = (rng.nextDouble() * h + math.cos(t * 0.25 + i * 0.8) * 30) % h;
      final radius = 30.0 + rng.nextDouble() * 50;
      final swirlAlpha = 0.08 + math.sin(t * 0.5 + i) * 0.04;

      final swirlPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius,
          [
            accentColor.withOpacity(swirlAlpha),
            fogColor.withOpacity(swirlAlpha * 0.5),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        );
      canvas.drawRect(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        swirlPaint,
      );
    }

    // Wavy horizontal mist bands
    for (double y = 0; y < h; y += 6) {
      final bandAlpha = (math.sin(y * 0.04 + t * 0.6) * 0.05 + 0.06) * opacity;
      final offsetX = math.sin(y * 0.02 + t * 0.4) * 8;
      final bandPaint = Paint()
        ..color = accentColor.withOpacity(bandAlpha.clamp(0.0, 0.15));
      canvas.drawRect(Rect.fromLTWH(offsetX, y, w, 3), bandPaint);
    }

    // Cut out the cleared areas to reveal content underneath
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear;
    canvas.drawPath(clearPath, clearPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FogShaderPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.clearPath != clearPath;
}

/// Interactive fog reveal widget - drag to clear the mist.
class FogRevealWidget extends StatefulWidget {
  final Widget child;
  final Color fogColor;
  final Color accentColor;
  final double fogOpacity;
  final double brushRadius;
  final bool initiallyRevealed;
  final VoidCallback? onFullyRevealed;

  const FogRevealWidget({
    super.key,
    required this.child,
    this.fogColor = const Color(0xFF2D2D3F),
    this.accentColor = const Color(0xFF6C63FF),
    this.fogOpacity = 0.85,
    this.brushRadius = 28.0,
    this.initiallyRevealed = false,
    this.onFullyRevealed,
  });

  @override
  State<FogRevealWidget> createState() => _FogRevealWidgetState();
}

class _FogRevealWidgetState extends State<FogRevealWidget>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  final Path _clearPath = Path();
  late bool _revealed;

  @override
  void initState() {
    super.initState();
    _revealed = widget.initiallyRevealed;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    
    // Fade out animation controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _addPoint(Offset localPos) {
    if (_revealed) return;
    setState(() {
      _clearPath.addOval(
        Rect.fromCircle(center: localPos, radius: widget.brushRadius),
      );
    });
  }

  void _checkReveal(Size size) {
    if (_revealed) return;
    final bounds = _clearPath.getBounds();
    
    // Check if size is valid (not infinite)
    if (!size.width.isFinite || !size.height.isFinite || size.width <= 0 || size.height <= 0) {
      print('[FogReveal] ⚠️ Invalid size: ${size.width}x${size.height}, using bounds instead');
      // Use the clear path bounds as a fallback
      if (bounds.width > 0 && bounds.height > 0) {
        // If we've drawn enough area, assume it's revealed
        // A typical card is about 300x150, so if we've cleared 70% of a reasonable area
        final drawnArea = bounds.width * bounds.height;
        const estimatedTotal = 300 * 150; // Reasonable card size
        final ratio = drawnArea / estimatedTotal;
        print('[FogReveal] Estimated ratio: ${(ratio * 100).toStringAsFixed(1)}%');
        if (ratio > 0.5) {  // Lowered threshold for estimated calculation
          _triggerReveal();
        }
      }
      return;
    }
    
    final area = bounds.width * bounds.height;
    final totalArea = size.width * size.height;
    final revealedRatio = area / totalArea;
    
    print('[FogReveal] Check reveal: area=$area, total=$totalArea (${size.width}x${size.height}), ratio=${(revealedRatio * 100).toStringAsFixed(1)}%');
    
    // If 70% or more is revealed, trigger full reveal with animation
    if (revealedRatio > 0.7) {
      _triggerReveal();
    }
  }
  
  void _triggerReveal() {
    print('[FogReveal] ✅ Threshold reached, triggering fade animation');
    setState(() {
      _revealed = true;
    });
    
    // Start fade out animation
    _fadeController.forward(from: 0.0);
    
    // Notify parent
    widget.onFullyRevealed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            // Content underneath
            widget.child,
            // Fog overlay with fade animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_animController, _fadeController]),
                builder: (context, _) {
                  // Calculate opacity: if revealed, use fade animation, otherwise use full opacity
                  final currentOpacity = _revealed 
                      ? widget.fogOpacity * _fadeAnimation.value 
                      : widget.fogOpacity;
                  
                  return GestureDetector(
                    onPanStart: (details) => _addPoint(details.localPosition),
                    onPanUpdate: (details) => _addPoint(details.localPosition),
                    onPanEnd: (_) => _checkReveal(size),
                    child: CustomPaint(
                      painter: FogShaderPainter(
                        time: _animController.value * 60.0,
                        fogColor: widget.fogColor,
                        accentColor: widget.accentColor,
                        clearPath: _clearPath,
                        opacity: currentOpacity,
                      ),
                      size: size,
                    ),
                  );
                },
              ),
            ),
            // Hint text
            if (!_revealed && _clearPath.getBounds().isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated finger icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, -8 + value * 8),
                              child: Opacity(
                                opacity: 0.7 + value * 0.3,
                                child: Icon(
                                  Icons.pan_tool_alt_rounded,
                                  color: widget.accentColor.withOpacity(0.8),
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Main hint text
                        Text(
                          '👆 滑动迷雾，揭开秘密',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle hint
                        Text(
                          '用手指在屏幕上滑动来解密内容',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

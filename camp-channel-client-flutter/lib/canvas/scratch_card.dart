import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Scratch card canvas - metallic cover that can be scratched away to reveal content.
/// Ported from PC client's Canvas2D scratch card (globalCompositeOperation).
class ScratchCardPainter extends CustomPainter {
  final Path scratchPath;
  final Color coverColor;
  final Color shimmerColor;
  final double coverOpacity;

  ScratchCardPainter({
    required this.scratchPath,
    this.coverColor = const Color(0xFF8D8D8D),
    this.shimmerColor = const Color(0xFFC0C0C0),
    this.coverOpacity = 0.95,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Save layer for composite operation
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());

    // Draw metallic cover
    final coverPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(w, h),
        [
          coverColor,
          shimmerColor,
          coverColor.withOpacity(0.9),
          shimmerColor.withOpacity(0.8),
        ],
        [0.0, 0.35, 0.65, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), coverPaint);

    // Draw shimmer pattern (diagonal lines)
    final linePaint = Paint()
      ..color = shimmerColor.withOpacity(0.15)
      ..strokeWidth = 1.5;
    for (double offset = -h; offset < w + h; offset += 8) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + h, h),
        linePaint,
      );
    }

    // Center text hint
    final textPainter = TextPainter(
      text: TextSpan(
        text: '刮开查看',
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, (h - textPainter.height) / 2),
    );

    // Cut out scratched areas using dstOut blend mode
    final scratchPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;

    canvas.drawPath(scratchPath, scratchPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchCardPainter oldDelegate) =>
      oldDelegate.scratchPath != scratchPath;
}

/// Interactive scratch card widget.
class ScratchCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color coverColor;
  final VoidCallback? onRevealed;

  const ScratchCard({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.coverColor = const Color(0xFF8D8D8D),
    this.onRevealed,
  });

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> {
  final Path _scratchPath = Path();
  bool _revealed = false;

  void _addScratch(Offset pos) {
    if (_revealed) return;
    setState(() {
      _scratchPath.lineTo(pos.dx, pos.dy);
    });
  }

  void _startScratch(Offset pos) {
    if (_revealed) return;
    setState(() {
      _scratchPath.moveTo(pos.dx, pos.dy);
    });
  }

  void _checkReveal() {
    if (_revealed) return;
    // Simple heuristic: if path has many points, consider revealed
    final metrics = _scratchPath.computeMetrics();
    double totalLength = 0;
    for (final m in metrics) {
      totalLength += m.length;
    }
    if (totalLength > widget.width * 2) {
      setState(() => _revealed = true);
      widget.onRevealed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Content underneath
            Positioned.fill(child: widget.child),
            // Scratch cover
            if (!_revealed)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (d) => _startScratch(d.localPosition),
                  onPanUpdate: (d) {
                    _addScratch(d.localPosition);
                    _checkReveal();
                  },
                  onPanEnd: (_) => _checkReveal(),
                  child: CustomPaint(
                    painter: ScratchCardPainter(
                      scratchPath: _scratchPath,
                      coverColor: widget.coverColor,
                    ),
                    size: Size(widget.width, widget.height),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

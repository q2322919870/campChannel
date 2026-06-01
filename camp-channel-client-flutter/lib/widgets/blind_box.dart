import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D flip animation blind box widget.
/// Tap to flip and reveal the hidden content.
class BlindBox extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width;
  final double height;
  final VoidCallback? onRevealed;

  const BlindBox({
    super.key,
    required this.front,
    required this.back,
    required this.width,
    required this.height,
    this.onRevealed,
  });

  @override
  State<BlindBox> createState() => _BlindBoxState();
}

class _BlindBoxState extends State<BlindBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flipAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) return;
    setState(() => _isFlipped = true);
    _controller.forward().then((_) => widget.onRevealed?.call());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, _) {
          final angle = _flipAnimation.value * math.pi;
          final isBackVisible = angle > math.pi / 2;

          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isBackVisible
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: widget.back,
                    )
                  : widget.front,
            ),
          );
        },
      ),
    );
  }
}

/// Pre-styled blind box card for announcements.
class AnnouncementBlindBox extends StatelessWidget {
  final String title;
  final String content;
  final String? coverImage;
  final bool isRevealed;

  const AnnouncementBlindBox({
    super.key,
    required this.title,
    required this.content,
    this.coverImage,
    this.isRevealed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 48;

    return BlindBox(
      width: cardWidth,
      height: 200,
      onRevealed: null,
      front: Container(
        width: cardWidth,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('盲盒公告', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('点击翻转揭晓', style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ],
        ),
      ),
      back: Container(
        width: cardWidth,
        height: 200,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, color: colorScheme.primary, size: 28),
            const SizedBox(height: 10),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6)),
                maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

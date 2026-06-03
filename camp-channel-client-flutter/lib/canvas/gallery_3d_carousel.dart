import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

/// Ported from PC client's Post3DGallery.ts (Three.js).
/// A 3D rotating carousel of image/video cards with perspective projection.
/// Supports drag to rotate, tap to select.
class Gallery3DItem {
  final int id;
  final String imageUrl;
  final String? videoUrl; // If present, this is a video item
  final String? title;
  final String? username;

  const Gallery3DItem({
    required this.id,
    required this.imageUrl,
    this.videoUrl,
    this.title,
    this.username,
  });

  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;
}

class Gallery3DCarousel extends StatefulWidget {
  final List<Gallery3DItem> items;
  final Color borderColor;
  final Color glowColor;
  final double height;
  final ValueChanged<Gallery3DItem>? onItemTap;

  const Gallery3DCarousel({
    super.key,
    required this.items,
    required this.borderColor,
    required this.glowColor,
    this.height = 220,
    this.onItemTap,
  });

  @override
  State<Gallery3DCarousel> createState() => _Gallery3DCarouselState();
}

class _Gallery3DCarouselState extends State<Gallery3DCarousel>
    with TickerProviderStateMixin {
  double _rotation = 0;
  double _targetRotation = 0;
  bool _dragging = false;
  int? _selectedId;
  late AnimationController _momentumController;
  double _lastDragX = 0;
  double _lastVelocity = 0;

  @override
  void initState() {
    super.initState();
    _momentumController = AnimationController(
      vsync: this,
    )..addListener(_onMomentum);
  }

  @override
  void dispose() {
    _momentumController.dispose();
    super.dispose();
  }

  void _onMomentum() {
    if (!mounted || _dragging) return;
    setState(() {
      _rotation += _lastVelocity;
      _targetRotation = _rotation;
      _lastVelocity *= 0.95;
      if (_lastVelocity.abs() < 0.001) {
        _momentumController.stop();
        // Auto-rotate slowly when idle
        _startAutoRotate();
      }
    });
  }

  Timer? _autoRotateTimer;

  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || _dragging) {
        timer.cancel();
        return;
      }
      setState(() {
        _rotation += 0.003;
        _targetRotation = _rotation;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startAutoRotate();
  }

  void _onPanStart(DragStartDetails details) {
    _dragging = true;
    _lastDragX = details.globalPosition.dx;
    _autoRotateTimer?.cancel();
    _momentumController.stop();
    // Sync rotation to target so dragging starts from current position
    _rotation = _targetRotation;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final delta = details.globalPosition.dx - _lastDragX;
    _rotation += delta * 0.012;
    _targetRotation = _rotation;
    _lastDragX = details.globalPosition.dx;
    _lastVelocity = delta * 0.012;
    if (mounted) setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _dragging = false;
    // Apply momentum from drag
    _lastVelocity = details.velocity.pixelsPerSecond.dx * 0.012;
    if (_lastVelocity.abs() > 0.005) {
      _momentumController.repeat();
    } else {
      _startAutoRotate();
    }
  }

  void _onItemTap(int index) {
    final item = widget.items[index];
    if (_selectedId == item.id) {
      widget.onItemTap?.call(item);
    } else {
      setState(() {
        _selectedId = item.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('暂无画作', style: TextStyle(color: Colors.white38))),
      );
    }

    final itemCount = widget.items.length;
    final cardWidth = 160.0;
    final cardHeight = 120.0;
    final radius = 180.0;

    // Sort items by z-depth for correct rendering order (far to near)
    final indices = List.generate(itemCount, (i) => i);
    indices.sort((a, b) {
      final angleA = (math.pi * 2 * a) / itemCount + _rotation;
      final angleB = (math.pi * 2 * b) / itemCount + _rotation;
      final zA = math.cos(angleA);
      final zB = math.cos(angleB);
      return zA.compareTo(zB);
    });

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onHorizontalDragStart: _onPanStart,
        onHorizontalDragUpdate: _onPanUpdate,
        onHorizontalDragEnd: _onPanEnd,
        child: Stack(
          alignment: Alignment.center,
          children: indices.map((i) {
            final angle = (math.pi * 2 * i) / itemCount + _rotation;
            final x = math.sin(angle) * radius;
            final z = math.cos(angle);
            final scale = 0.5 + (z + 1) * 0.25;
            final opacity = 0.3 + (z + 1) * 0.35;
            final isSelected = _selectedId == widget.items[i].id;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translate(x, -z * 20)
                ..scale(isSelected ? 1.3 : scale),
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: GestureDetector(
                  onTap: () => _onItemTap(i),
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : widget.borderColor.withOpacity(0.4),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor.withOpacity(isSelected ? 0.4 : 0.15),
                          blurRadius: isSelected ? 20 : 8,
                          spreadRadius: isSelected ? 2 : 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          widget.items[i].isVideo
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      widget.items[i].imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.black),
                                    ),
                                    const Center(
                                      child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 40),
                                    ),
                                  ],
                                )
                              : Image.network(
                                  widget.items[i].imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.black26,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: widget.glowColor,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Gallery image load error: $error');
                                    debugPrint('Image URL: ${widget.items[i].imageUrl}');
                                    return Container(
                                      color: Colors.black26,
                                      child: const Icon(Icons.image, color: Colors.white38, size: 32),
                                    );
                                  },
                                ),
                          if (widget.items[i].isVideo)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('视频', style: TextStyle(color: Colors.white, fontSize: 9)),
                              ),
                            ),
                          if (widget.items[i].title != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                  ),
                                ),
                                child: Text(
                                  widget.items[i].title!,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

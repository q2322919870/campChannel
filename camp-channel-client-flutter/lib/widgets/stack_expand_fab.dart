import 'package:flutter/material.dart';

/// Stack-expandable FAB: tap main button to reveal child buttons with staggered animation.
class StackExpandFab extends StatefulWidget {
  final List<StackFabItem> items;
  final Color? mainColor;

  const StackExpandFab({
    super.key,
    required this.items,
    this.mainColor,
  });

  @override
  State<StackExpandFab> createState() => _StackExpandFabState();
}

class StackFabItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const StackFabItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _StackExpandFabState extends State<StackExpandFab>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainColor = widget.mainColor ?? colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded items (reverse order so first item is at top)
        ...List.generate(widget.items.length, (i) {
          final item = widget.items[widget.items.length - 1 - i];
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = i * 0.15;
              final value = (_controller.value - delay).clamp(0.0, 1.0) / (1.0 - delay);
              return Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: item.color ?? mainColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        _toggle();
                        item.onTap();
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(item.icon, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Main button
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _expanded
                    ? [colorScheme.secondary, mainColor]
                    : [mainColor, colorScheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _expanded ? Icons.close : Icons.add,
                key: ValueKey(_expanded),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

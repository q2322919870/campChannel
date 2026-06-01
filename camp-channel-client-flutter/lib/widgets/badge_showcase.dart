import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

/// Badge showcase widget - displays earned badges with shader glow animation.
class BadgeShowcase extends StatefulWidget {
  const BadgeShowcase({super.key});

  @override
  State<BadgeShowcase> createState() => _BadgeShowcaseState();
}

class _BadgeShowcaseState extends State<BadgeShowcase>
    with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _badges = [];
  bool _isLoading = true;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _fetchBadges();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchBadges() async {
    try {
      final response = await _apiClient.get('/badges/my');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _badges = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.emoji_events_outlined, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('徽章墙', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('发帖和获赞可解锁成就徽章',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('已获徽章 (${_badges.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _badges.length,
              itemBuilder: (context, index) {
                final badge = _badges[index];
                return _buildBadgeItem(badge, index, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(Map<String, dynamic> badge, int index, ColorScheme colorScheme) {
    final name = badge['badgeName']?.toString() ?? '未知';
    final icon = badge['badgeIcon']?.toString() ?? '🏆';

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * math.pi * 2;
        final glowAlpha = math.sin(t + index * 0.8) * 0.3 + 0.4;

        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withOpacity(glowAlpha * 0.3),
                      colorScheme.secondary.withOpacity(glowAlpha * 0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(glowAlpha * 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(glowAlpha * 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 6),
              Text(name,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.7)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

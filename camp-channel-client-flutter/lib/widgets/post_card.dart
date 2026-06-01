import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String title;
  final String content;
  final List<String>? images;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isPinned;
  final bool showPinOption;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final String? channelName;
  final DateTime? timestamp;

  const PostCard({
    super.key,
    required this.username,
    this.avatarUrl = '',
    required this.title,
    required this.content,
    this.images,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    this.showPinOption = false,
    this.onLike,
    this.onComment,
    this.onTap,
    this.onPin,
    this.channelName,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 14, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          '置顶',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildHeader(context),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (images != null && images!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildImageGrid(context),
                ],
                const SizedBox(height: 12),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageFilter _getBlurFilter(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
        : ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: avatarUrl.isNotEmpty
                ? Image.network(
                    ApiClient.processImageUrl(avatarUrl),
                    width: 36, height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (timestamp != null)
                Text(
                  _formatTime(timestamp!),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
        if (channelName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '# $channelName',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    if (images == null || images!.isEmpty) return const SizedBox.shrink();
    final count = images!.length;
    if (count == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          ApiClient.processImageUrl(images![0]),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImage(context),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count == 2 ? 2 : 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count > 9 ? 9 : count,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ApiClient.processImageUrl(images![i]),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderImage(context),
        ),
      ),
    );
  }

  Widget _placeholderImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onLike,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLiked
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  formatCount(likeCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: isLiked ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onComment,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  formatCount(commentCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_horiz, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          onSelected: (value) {
            if (value == 'report' && onTap != null) onTap!();
            if (value == 'pin' && onPin != null) onPin!();
          },
          itemBuilder: (context) => [
            if (showPinOption)
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text(isPinned ? '取消置顶' : '置顶'),
                  ],
                ),
              ),
            const PopupMenuItem(value: 'report', child: Row(
              children: [Icon(Icons.flag_outlined, size: 16), SizedBox(width: 8), Text('举报')],
            )),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  String formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

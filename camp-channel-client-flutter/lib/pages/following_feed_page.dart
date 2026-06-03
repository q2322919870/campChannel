import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../widgets/post_card.dart';
import '../widgets/user_card.dart';

class FollowingFeedPage extends StatefulWidget {
  const FollowingFeedPage({super.key});

  @override
  State<FollowingFeedPage> createState() => _FollowingFeedPageState();
}

class _FollowingFeedPageState extends State<FollowingFeedPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final response = await _apiClient.get('/follow/feed', queryParameters: {'page': 1, 'size': 50});
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _posts = list.map((e) => e as Map<String, dynamic>).toList();
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('还没有关注任何人', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text('关注用户后，他们的帖子会出现在这里', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFeed,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final rawContent = post['content']?.toString() ?? '';
          final rawTopic = post['topic']?.toString() ?? '';
          final displayTitle = rawTopic.isNotEmpty ? rawTopic : (rawContent.length > 50 ? '${rawContent.substring(0, 50)}...' : rawContent);
          List<String> imageList = [];
          final rawImages = post['images'];
          if (rawImages is List) {
            imageList = rawImages.map((e) => e.toString()).toList();
          } else if (rawImages is String && rawImages.isNotEmpty) {
            try {
              final parsed = (rawImages.startsWith('['))
                  ? (json.decode(rawImages) as List).map((e) => e.toString()).toList()
                  : rawImages.split(',');
              imageList = parsed;
            } catch (_) {}
          }
          return PostCard(
            username: post['username']?.toString() ?? '匿名',
            avatarUrl: ApiClient.processImageUrl(post['avatar']?.toString()),
            title: displayTitle,
            content: rawContent,
            images: imageList,
            likeCount: post['likeCount'] ?? 0,
            commentCount: post['commentCount'] ?? 0,
            timestamp: post['createTime'] != null
                ? DateTime.tryParse(post['createTime'].toString())
                : null,
            onTap: () => Navigator.pushNamed(context, '/post_detail', arguments: post),
            onComment: () => Navigator.pushNamed(context, '/post_detail', arguments: post),
          );
        },
      ),
    );
  }
}

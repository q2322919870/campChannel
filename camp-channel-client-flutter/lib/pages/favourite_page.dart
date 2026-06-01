import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../widgets/user_card.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _favourites = [];
  bool _isLoading = true;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = refresh);

    try {
      final response = await _apiClient.get(
        '/posts/favourites',
        queryParameters: {'page': _page, 'size': _pageSize},
      );
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        final posts = list.map((e) => e as Map<String, dynamic>).toList();

        if (mounted) {
          setState(() {
            if (refresh) {
              _favourites = posts;
            } else {
              _favourites.addAll(posts);
            }
            _hasMore = posts.length >= _pageSize;
            if (posts.isNotEmpty) {
              _page++;
            }
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

  Future<void> _removeFavourite(String postId) async {
    try {
      final response = await _apiClient.post('/posts/$postId/favourite');
      final result = response.data;
      if (result != null && result['code'] == 200) {
        // Remove from list
        setState(() {
          _favourites.removeWhere((p) => p['id'].toString() == postId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消收藏'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToPostDetail(Map<String, dynamic> post) {
    Navigator.pushNamed(context, '/post_detail', arguments: post).then((result) {
      // Refresh if post was deleted
      if (result == true) {
        _loadFavourites(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _isLoading && _favourites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _favourites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('暂无收藏', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('浏览帖子并点击收藏按钮', style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadFavourites(refresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favourites.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _favourites.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final post = _favourites[index];
                      return _buildPostCard(post);
                    },
                  ),
                ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = post['username']?.toString() ?? '匿名';
    final content = post['content']?.toString() ?? '';
    final channelName = post['channelName']?.toString() ?? '';
    final timeStr = post['createTime']?.toString() ?? '';
    final likeCount = post['likeCount'] ?? 0;
    final commentCount = post['commentCount'] ?? 0;
    final avatarUrl = post['avatar'] as String?;
    final processedAvatar = ApiClient.processImageUrl(avatarUrl);

    return GestureDetector(
      onTap: () => _navigateToPostDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: processedAvatar.isNotEmpty
                        ? Image.network(processedAvatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                        : Center(child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(timeStr.isNotEmpty ? '${_formatTime(timeStr)} · $channelName' : channelName,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark, size: 20),
                  color: colorScheme.primary,
                  onPressed: () => _removeFavourite(post['id'].toString()),
                  tooltip: '取消收藏',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text('$likeCount', style: theme.textTheme.bodySmall),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text('$commentCount', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return '刚刚';
      if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
      if (difference.inHours < 24) return '${difference.inHours}小时前';
      if (difference.inDays < 7) return '${difference.inDays}天前';
      return '${dateTime.month}月${dateTime.day}日';
    } catch (_) {
      return timeStr;
    }
  }
}

import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

class HotPostsPage extends StatefulWidget {
  const HotPostsPage({super.key});

  @override
  State<HotPostsPage> createState() => _HotPostsPageState();
}

class _HotPostsPageState extends State<HotPostsPage> {
  final _apiClient = ApiClient();
  final List<Map<String, dynamic>> _hotPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotPosts();
  }

  Future<void> _loadHotPosts() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.get(
        '/posts/hot',
        queryParameters: {'limit': 20},
      );
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _hotPosts.clear();
            _hotPosts.addAll(list.map((e) => e as Map<String, dynamic>).toList());
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('热门帖子'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hotPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 64,
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无热门帖子',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHotPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _hotPosts.length,
                    itemBuilder: (context, index) {
                      final post = _hotPosts[index];
                      return PostCard(
                        username: post['username'] ?? '未知用户',
                        avatarUrl: post['avatar'] ?? '',
                        title: post['topic'] ?? '帖子',
                        content: post['content'] ?? '',
                        images: post['images'] != null
                            ? (post['images'] as List).cast<String>()
                            : null,
                        likeCount: post['likeCount'] ?? 0,
                        commentCount: post['commentCount'] ?? 0,
                        isLiked: post['isLiked'] == true,
                        isPinned: post['isPinned'] == 1,
                        timestamp: post['createTime'] != null
                            ? DateTime.tryParse(post['createTime'].toString())
                            : null,
                        onLike: () {},
                        onComment: () {
                          Navigator.pushNamed(
                            context,
                            '/post_detail',
                            arguments: post,
                          );
                        },
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/post_detail',
                            arguments: post,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

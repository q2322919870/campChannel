import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/burst_service.dart';
import '../canvas/canvas_effects.dart';
import '../widgets/post_card.dart';
import '../widgets/stack_expand_fab.dart';

class ChannelFeedPage extends StatefulWidget {
  const ChannelFeedPage({super.key});

  @override
  State<ChannelFeedPage> createState() => _ChannelFeedPageState();
}

class _ChannelFeedPageState extends State<ChannelFeedPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _channels = [];
  int? _activeChannelId;
  bool _isLoading = true;
  List<Gallery3DItem> _galleryItems = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _fetchPosts();
    _fetchGalleryItems();
  }

  Future<void> _fetchGalleryItems() async {
    try {
      final response = await _apiClient.get('/gallery');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _galleryItems = list.map((e) {
              final g = Map<String, dynamic>.from(e as Map);
              return Gallery3DItem(
                id: g['id'] ?? 0,
                imageUrl: ApiClient.processImageUrl(g['imageUrl']?.toString() ?? ''),
                title: g['title']?.toString() ?? '',
                username: g['username']?.toString() ?? '匿名',
              );
            }).where((item) => item.imageUrl.isNotEmpty).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadChannels() async {
    try {
      final response = await _apiClient.get('/channels/my');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _channels = list.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final url = _activeChannelId == null
          ? '/posts'
          : '/posts/channel/$_activeChannelId';
      final response = await _apiClient.get(url);
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = (result['data'] is List)
            ? result['data'] as List
            : (result['data']['records'] as List? ?? []);
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

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final postId = post['id'];
    if (postId == null) return;
    try {
      final response = await _apiClient.post('/posts/$postId/like');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final liked = data['liked'] == true;
        final likeCount = data['likeCount'] as int? ?? (post['likeCount'] as int? ?? 0);
        setState(() {
          post['isLiked'] = liked;
          post['likeCount'] = likeCount;
        });
        // Trigger particle burst on like (same as PC client)
        if (liked && mounted) {
          try {
            final burstService = BurstService.maybeOf(context);
            if (burstService != null) {
              final size = MediaQuery.of(context).size;
              burstService.triggerBurst(
                size.width * 0.15,
                size.height * 0.5 + index * 60.0,
                color: Theme.of(context).colorScheme.primary,
              );
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeChannel = _activeChannelId != null
        ? _channels.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c!['id'] == _activeChannelId,
            orElse: () => null,
          )
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _activeChannelId != null && activeChannel != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(activeChannel['name']?.toString() ?? '频道'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '搜索帖子',
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  tooltip: '频道群聊',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/group_chat',
                    arguments: {
                      'channelId': _activeChannelId,
                      'channelName': activeChannel['name']?.toString() ?? '群聊',
                    },
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Camp Channel'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.local_fire_department),
                  tooltip: '热门帖子',
                  color: Colors.orange,
                  onPressed: () => Navigator.pushNamed(context, '/hot_posts'),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '搜索帖子',
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Channel tabs
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _channels.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final isActive = isAll ? _activeChannelId == null : _activeChannelId == _channels[index - 1]['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeChannelId = isAll ? null : _channels[index - 1]['id'] as int?;
                      });
                      _fetchPosts();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(colors: [colorScheme.primary, colorScheme.primary])
                            : null,
                        color: isActive ? null : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? Colors.transparent : colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isAll ? '全部' : _channels[index - 1]['name']?.toString() ?? '',
                          style: TextStyle(
                            color: isActive ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Post list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchPosts,
                    child: _posts.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.article_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                                      const SizedBox(height: 16),
                                      Text('暂无帖子', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _posts.length + 1,
                            itemBuilder: (context, index) {
                              // First item: 3D gallery section
                              if (index == 0) {
                                if (_galleryItems.isEmpty) {
                                  return Container(
                                    height: 160,
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: theme.cardColor.withOpacity(0.6),
                                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.photo_library_outlined, size: 40, color: colorScheme.primary.withOpacity(0.4)),
                                          const SizedBox(height: 8),
                                          Text('画廊暂无画作', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Gallery3DCarousel(
                                    items: _galleryItems,
                                    borderColor: colorScheme.primary,
                                    glowColor: colorScheme.secondary,
                                    height: 200,
                                    onItemTap: (item) {
                                      // Show gallery image preview dialog
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              item.imageUrl,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const SizedBox(
                                                height: 200, child: Center(child: Text('图片加载失败')),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                              final postIndex = index - 1;
                              if (postIndex >= _posts.length) return const SizedBox.shrink();
                              final post = _posts[postIndex];
                              final rawTitle = post['topic']?.toString() ?? '';
                              final rawContent = post['content']?.toString() ?? '';
                              final displayTitle = rawTitle.isNotEmpty
                                  ? rawTitle
                                  : (rawContent.length > 50
                                      ? '${rawContent.substring(0, 50)}...'
                                      : rawContent);
                              // Wrap with ShaderCard effect (alternating glass/glitch like PC)
                              final useGlitch = postIndex % 3 == 0 && _channels.isNotEmpty;
                              return ShaderCard(
                                mood: useGlitch ? MoodMode.glitch : MoodMode.glass,
                                intensity: 0.15,
                                child: PostCard(
                                  username: post['author']?.toString() ?? post['username']?.toString() ?? '匿名',
                                  avatarUrl: post['avatar']?.toString() ?? '',
                                  title: displayTitle,
                                  content: rawContent,
                                  likeCount: post['likeCount'] ?? 0,
                                  commentCount: post['commentCount'] ?? 0,
                                  isLiked: post['isLiked'] ?? false,
                                  isPinned: post['isPinned'] == 1 || post['isPinned'] == true,
                                  channelName: post['channelName']?.toString(),
                                  timestamp: post['createTime'] != null
                                      ? DateTime.tryParse(post['createTime'].toString())
                                      : null,
                                  onLike: () => _toggleLike(postIndex),
                                  onComment: () => Navigator.pushNamed(context, '/post_detail', arguments: post),
                                  onTap: () => Navigator.pushNamed(context, '/post_detail', arguments: post),
                                ),
                              );
                            },
                  ),
          ),
          ),
        ],
      ),
      ),
      floatingActionButton: StackExpandFab(
        items: [
          StackFabItem(
            icon: Icons.photo_camera,
            label: '上传画作',
            color: colorScheme.secondary,
            onTap: () => Navigator.pushNamed(context, '/gallery_upload'),
          ),
          StackFabItem(
            icon: Icons.psychology,
            label: '树洞',
            color: colorScheme.tertiary,
            onTap: () => Navigator.pushNamed(context, '/tree_hole'),
          ),
          StackFabItem(
            icon: Icons.edit_note,
            label: '发帖',
            onTap: () => Navigator.pushNamed(context, '/create_post'),
          ),
        ],
      ),
    );
  }
}

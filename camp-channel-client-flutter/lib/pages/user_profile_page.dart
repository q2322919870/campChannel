import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../widgets/user_card.dart';
import 'package:dio/dio.dart';

class UserProfilePage extends StatefulWidget {
  final int userId;
  final String? username;
  final String? avatarUrl;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.username,
    this.avatarUrl,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  String _displayName = '';
  String? _displayAvatar;
  String? _displayEmail;
  int _followerCount = 0;
  int _followingCount = 0;
  int _postCount = 0;
  bool _isFriend = false;
  bool _isFollowing = false;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      // Fetch user profile with posts
      final profileRes = await _apiClient.get('/users/${widget.userId}/profile');
      final profileResult = profileRes.data;
      
      if (profileResult != null && profileResult['code'] == 200) {
        final data = profileResult['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _displayName = data['username']?.toString() ?? widget.username ?? '未知用户';
            _displayAvatar = data['avatar']?.toString() ?? widget.avatarUrl;
            _displayEmail = data['email']?.toString();
            _isFriend = data['isFriend'] as bool? ?? false;
            _isLoading = false;
          });
        }
        
        // Parse posts
        if (data['posts'] != null) {
          final postsList = data['posts'] as List;
          if (mounted) {
            setState(() {
              _posts = postsList.map((e) => e as Map<String, dynamic>).toList();
              _postCount = _posts.length;
              _isLoadingPosts = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingPosts = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }

    // Fetch follow counts
    try {
      final countRes = await _apiClient.get('/follow/${widget.userId}/counts');
      final countResult = countRes.data;
      if (countResult != null && countResult['code'] == 200) {
        final data = countResult['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _followerCount = data['followerCount'] ?? 0;
            _followingCount = data['followingCount'] ?? 0;
          });
        }
      }
    } catch (_) {}

    // Fetch follow status
    final currentUserId = StorageService.getUserId();
    if (currentUserId != widget.userId) {
      try {
        final followRes = await _apiClient.get('/follow/${widget.userId}/is-following');
        final followResult = followRes.data;
        if (followResult != null && followResult['code'] == 200) {
          if (mounted) {
            setState(() {
              _isFollowing = followResult['data'] as bool? ?? false;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final response = await _apiClient.post('/follow/${widget.userId}/toggle');
      final result = response.data;
      if (result != null && result['code'] == 200) {
        final followed = result['data'] as bool;
        if (mounted) {
          setState(() {
            _isFollowing = followed;
            _followerCount += followed ? 1 : -1;
            if (_followerCount < 0) _followerCount = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(followed ? '已关注' : '已取消关注'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? '操作失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addFriend() async {
    try {
      await _apiClient.post('/friends/request', data: {'friendId': widget.userId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('好友请求已发送'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? '操作失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAvatarPreview() {
    if (_displayAvatar == null || _displayAvatar!.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                ApiClient.processImageUrl(_displayAvatar!),
                width: 250,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.person, size: 80, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(_displayName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = StorageService.getUserId();
    final isMyself = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? '用户主页' : _displayName),
        actions: [
          if (!isMyself)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('举报功能开发中')),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'report', child: Text('举报用户')),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // User info header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _showAvatarPreview,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colorScheme.primary, colorScheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: _displayAvatar != null && _displayAvatar!.isNotEmpty
                                  ? Image.network(
                                      ApiClient.processImageUrl(_displayAvatar!),
                                      fit: BoxFit.cover,
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Username
                        Text(
                          _displayName,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_displayEmail != null && _displayEmail!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _displayEmail!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/follow_list', arguments: {
                                  'userId': widget.userId,
                                  'username': _displayName,
                                  'tab': 'followers',
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_followerCount',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text('粉丝', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/follow_list', arguments: {
                                  'userId': widget.userId,
                                  'username': _displayName,
                                  'tab': 'following',
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_followingCount',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text('关注', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_postCount',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text('帖子', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (!isMyself)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/chat_detail', arguments: {
                                    'friendId': widget.userId,
                                    'friendName': _displayName,
                                    'friendAvatar': _displayAvatar,
                                  });
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                label: const Text('私聊'),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            if (!isMyself && !_isFriend)
                              ElevatedButton.icon(
                                onPressed: _addFriend,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('加好友'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            if (!isMyself)
                              ElevatedButton.icon(
                                onPressed: _toggleFollow,
                                icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                                label: Text(_isFollowing ? '已关注' : '关注'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  backgroundColor: _isFollowing ? colorScheme.surface : null,
                                  foregroundColor: _isFollowing ? colorScheme.primary : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider()),
                // Posts section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.article_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text('TA 的帖子', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        Text('${_posts.length} 篇', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                // Posts list
                _isLoadingPosts
                    ? const SliverToBoxAdapter(
                        child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                      )
                    : _posts.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.article_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                                    const SizedBox(height: 8),
                                    Text('暂无帖子', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = _posts[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (post['topic']?.toString() ?? post['content']?.toString() ?? '').isEmpty
                                            ? ''
                                            : (post['topic']?.toString() ?? '').isNotEmpty
                                                ? post['topic']!.toString()
                                                : (post['content']!.toString().length > 50
                                                    ? '${post['content']!.toString().substring(0, 50)}...'
                                                    : post['content']!.toString()),
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post['content']?.toString() ?? '',
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (post['images'] != null && (post['images'] as List).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: SizedBox(
                                            height: 60,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: (post['images'] as List).length,
                                              itemBuilder: (context, imgIndex) {
                                                final imgUrl = (post['images'] as List)[imgIndex].toString();
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 4),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      ApiClient.processImageUrl(imgUrl),
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: colorScheme.surface,
                                                        child: Icon(Icons.image, size: 24, color: colorScheme.onSurface.withOpacity(0.3)),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post['createTime']?.toString() ?? '',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: _posts.length,
                            ),
                          ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
    );
  }
}

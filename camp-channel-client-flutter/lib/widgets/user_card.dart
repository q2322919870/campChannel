import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';

class UserCard extends StatefulWidget {
  final int userId;
  final String username;
  final String? avatarUrl;
  final String? email;

  const UserCard({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.email,
  });

  static void show(BuildContext context, {
    required int userId,
    required String username,
    String? avatarUrl,
    String? email,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserCard(
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        email: email,
      ),
    );
  }

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoadingPosts = true;
  bool _isFriend = false;
  bool _isLoadingFriendStatus = true;
  bool _isFollowing = false;
  bool _isLoadingFollowStatus = true;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _checkFriendStatus();
    _checkFollowStatus();
    _fetchFollowCounts();
  }

  Future<void> _checkFollowStatus() async {
    final currentUserId = StorageService.getUserId();
    if (currentUserId == widget.userId) {
      if (mounted) setState(() => _isLoadingFollowStatus = false);
      return;
    }
    try {
      final response = await _apiClient.get('/follow/${widget.userId}/is-following');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        if (mounted) {
          setState(() {
            _isFollowing = result['data'] as bool;
            _isLoadingFollowStatus = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFollowStatus = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFollowStatus = false);
    }
  }

  Future<void> _fetchFollowCounts() async {
    try {
      final response = await _apiClient.get('/follow/${widget.userId}/counts');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _followerCount = data['followerCount'] ?? 0;
            _followingCount = data['followingCount'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    try {
      final response = await _apiClient.post('/follow/${widget.userId}/toggle');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
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

  Future<void> _checkFriendStatus() async {
    try {
      final response = await _apiClient.get('/friends');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        final friendIds = list.map((f) => f['id'] ?? f['userId']).whereType<int>().toList();
        if (mounted) {
          setState(() {
            _isFriend = friendIds.contains(widget.userId);
            _isLoadingFriendStatus = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFriendStatus = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFriendStatus = false);
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await _apiClient.get('/posts/user/${widget.userId}');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _posts = list.map((e) => e as Map<String, dynamic>).toList();
            _isLoadingPosts = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPosts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _addFriend() async {
    try {
      await _apiClient.post('/friends/requests', data: {'userId': widget.userId});
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
    if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty) return;
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
                ApiClient.processImageUrl(widget.avatarUrl!),
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
            Text(widget.username, style: Theme.of(context).textTheme.titleMedium),
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
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showAvatarPreview,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                      ? Image.network(
                          ApiClient.processImageUrl(widget.avatarUrl!),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              widget.username[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.username, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (widget.email != null && widget.email!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.email!, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Follower / Following counts
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/follow_list', arguments: {
                      'userId': widget.userId,
                      'username': widget.username,
                      'tab': 'followers',
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_followerCount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('粉丝', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/follow_list', arguments: {
                      'userId': widget.userId,
                      'username': widget.username,
                      'tab': 'following',
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_followingCount', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text('关注', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat_detail', arguments: {
                      'friendId': widget.userId,
                      'friendName': widget.username,
                      'friendAvatar': widget.avatarUrl,
                    });
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('私聊'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 12),
                // Follow / Unfollow button
                if (widget.userId != StorageService.getUserId() && !_isLoadingFollowStatus)
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
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            Expanded(
              child: _isLoadingPosts
                  ? const Center(child: CircularProgressIndicator())
                  : _posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 8),
                              Text('暂无帖子', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _posts.length,
                          itemBuilder: (_, i) {
                            final post = _posts[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
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
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

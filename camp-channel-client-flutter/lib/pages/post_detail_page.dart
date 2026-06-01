import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../widgets/comment_widget.dart';
import '../widgets/user_card.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isFavourited = false;
  int _favouriteCount = 0;
  bool _isPinned = false;
  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 必须在第一帧渲染完毕后才能读取 ModalRoute 路由参数
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPost());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadPost() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _post = args;
      _isLiked = args['isLiked'] ?? false;
      _likeCount = args['likeCount'] ?? 0;
      _isFavourited = args['isFavourited'] ?? false;
      _favouriteCount = args['favouriteCount'] ?? 0;
      _isPinned = args['isPinned'] == 1 || args['isPinned'] == true;
      final postId = args['id'];
      if (postId != null) {
        _fetchComments(postId.toString());
        _loadFavouriteStatus(postId.toString());
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavouriteStatus(String postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId/favourite/status');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _isFavourited = data['isFavourited'] ?? false;
            _favouriteCount = data['count'] ?? 0;
            // Also update the original post map reference
            if (_post != null) {
              _post!['isFavourited'] = _isFavourited;
              _post!['favouriteCount'] = _favouriteCount;
            }
          });
        }
      }
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> _fetchComments(String postId) async {
    try {
      final response = await _apiClient.get('/posts/$postId/comments');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _comments = list.map((e) => e as Map<String, dynamic>).toList();
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final postId = _post?['id']?.toString();
    if (postId == null) return;

    try {
      final response = await _apiClient.post('/posts/$postId/comments', data: {
        'content': _commentController.text.trim(),
      });
      final result = response.data;
      if (result != null && result['code'] == 200) {
        _commentController.clear();
        await _fetchComments(postId);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? '评论失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final postId = _post?['id']?.toString();
    if (postId == null) return;
    try {
      final response = await _apiClient.post('/posts/$postId/like');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final liked = data['liked'] == true;
        final likeCount = data['likeCount'] as int? ?? _likeCount;
        setState(() {
          _isLiked = liked;
          _likeCount = likeCount;
          // Also update the original post map reference to sync back to the home page
          if (_post != null) {
            _post!['isLiked'] = liked;
            _post!['likeCount'] = likeCount;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    final postId = _post?['id']?.toString();
    if (postId == null) return;
    try {
      final response = await _apiClient.post('/posts/$postId/favourite');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final favourited = data['isFavourited'] == true;
        setState(() {
          _isFavourited = favourited;
          _favouriteCount = favourited ? _favouriteCount + 1 : (_favouriteCount > 0 ? _favouriteCount - 1 : 0);
          // Also update the original post map reference
          if (_post != null) {
            _post!['isFavourited'] = favourited;
            _post!['favouriteCount'] = _favouriteCount;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(favourited ? '收藏成功' : '已取消收藏'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePin() async {
    final postId = _post?['id']?.toString();
    if (postId == null) return;
    try {
      final response = await _apiClient.post('/posts/$postId/pin');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final pinned = data['isPinned'] == true;
        if (mounted) {
          setState(() {
            _isPinned = pinned;
            if (_post != null) {
              _post!['isPinned'] = pinned ? 1 : 0;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? (pinned ? '已置顶' : '已取消置顶')),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }

  void _sharePost() {
    if (_post == null) return;
    
    final title = _post?['topic']?.toString() ?? _post?['content']?.toString() ?? '';
    final content = _post?['content']?.toString() ?? '';
    
    // Show share options
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy_all, color: Theme.of(context).colorScheme.primary),
              title: const Text('复制内容'),
              subtitle: Text(
                '📝 $title\n\n$content\n\n—— 来自 Camp Channel',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已复制: $title')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _reportPost() async {
    final postId = _post?['id']?.toString();
    if (postId == null) return;
    
    try {
      final response = await _apiClient.post('/posts/$postId/report');
      final result = response.data;
      if (mounted) {
        if (result != null && result['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('举报成功，我们会尽快处理')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '举报失败')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报失败，请重试')),
        );
      }
    }
  }

  Future<void> _deletePost() async {
    final postId = _post?['id']?.toString();
    if (postId == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这个帖子吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      final response = await _apiClient.delete('/posts/$postId');
      final result = response.data;
      if (mounted) {
        if (result != null && result['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          Navigator.pop(context, true); // Return to previous page
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '删除失败')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('帖子详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final username = _post?['username']?.toString() ?? _post?['author']?.toString() ?? '匿名';
    final rawTopic = _post?['topic']?.toString() ?? '';
    final rawContent = _post?['content']?.toString() ?? '';
    final title = rawTopic.isNotEmpty ? rawTopic : (rawContent.length > 50 ? '${rawContent.substring(0, 50)}...' : rawContent);
    final content = rawContent;
    final channelName = _post?['channelName']?.toString() ?? '';
    final avatarUrl = _post?['avatar'] as String?;
    final processedAvatar = ApiClient.processImageUrl(avatarUrl);
    final userId = _post?['userId'] is int ? _post!['userId'] as int : 0;
    final email = _post?['email'] as String?;
    final timeStr = _post?['createTime']?.toString() ?? _post?['createdAt']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _sharePost,
            tooltip: '分享',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            tooltip: '更多',
            onSelected: (value) {
              switch (value) {
                case 'favourite':
                  _toggleFavourite();
                  break;
                case 'report':
                  _reportPost();
                  break;
                case 'delete':
                  _deletePost();
                  break;
              }
            },
            itemBuilder: (context) {
              final currentUserId = StorageService.getUserId();
              final postUserId = _post?['userId'] is int
                  ? _post!['userId'] as int
                  : int.tryParse(_post?['userId']?.toString() ?? '');
              final isOwnPost =
                  currentUserId != null && postUserId != null && currentUserId == postUserId;

              if (isOwnPost) {
                return [
                  const PopupMenuItem(value: 'delete', child: Text('删除帖子')),
                ];
              } else {
                return [
                  PopupMenuItem(
                    value: 'favourite',
                    child: Row(
                      children: [
                        Icon(
                          _isFavourited ? Icons.bookmark : Icons.bookmark_border,
                          size: 20,
                          color: _isFavourited ? Theme.of(context).colorScheme.primary : null,
                        ),
                        const SizedBox(width: 8),
                        Text(_isFavourited ? '已收藏' : '收藏'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(value: 'report', child: Text('举报')),
                ];
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userId > 0) {
                        UserCard.show(context,
                          userId: userId,
                          username: username,
                          avatarUrl: avatarUrl,
                          email: email,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: processedAvatar.isNotEmpty
                                ? Image.network(
                                    processedAvatar,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              timeStr.isNotEmpty ? '${_formatTime(timeStr)} · $channelName' : channelName,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isPinned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                          const SizedBox(width: 6),
                          const Text(
                            '此帖已被置顶',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isLiked ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: _isLiked ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_likeCount',
                                style: TextStyle(
                                  color: _isLiked ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 6),
                            Text('${_comments.length}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_canPinPost)
                        GestureDetector(
                          onTap: _togglePin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isPinned ? Colors.amber.withOpacity(0.1) : colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isPinned ? Colors.amber.withOpacity(0.3) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: _isPinned ? Colors.amber : colorScheme.onSurface.withOpacity(0.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isPinned ? '已置顶' : '置顶',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isPinned ? Colors.amber : colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_canPinPost) const SizedBox(width: 8),
                      Icon(Icons.bookmark_border, color: colorScheme.onSurface.withOpacity(0.4)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('评论 (${_comments.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('在评论中使用 @用户名 可以提及他人',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  const SizedBox(height: 8),
                  ..._comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CommentWidget(
                      username: c['username']?.toString() ?? c['user']?.toString() ?? '匿名',
                      content: c['content']?.toString() ?? '',
                      likeCount: c['likes'] ?? c['likeCount'] ?? 0,
                      avatarUrl: ApiClient.processImageUrl(c['avatar'] as String?),
                      isOwn: c['userId']?.toString() == StorageService.getUserId()?.toString(),
                      onAvatarTap: () {
                        final uid = c['userId'] is int ? c['userId'] as int : int.tryParse(c['userId']?.toString() ?? '');
                        if (uid != null && uid > 0) {
                          UserCard.show(context,
                            userId: uid,
                            username: c['username']?.toString() ?? '匿名',
                            avatarUrl: ApiClient.processImageUrl(c['avatar'] as String?),
                            email: c['email'] as String?,
                          );
                        }
                      },
                      timestamp: c['createdAt'] != null
                          ? DateTime.tryParse(c['createdAt'].toString())
                          : null,
                    ),
                  )),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '写下你的评论...',
                          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _submitComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  bool get _canPinPost {
    final role = _post?['userChannelRole']?.toString() ?? '';
    return role == 'owner' || role == 'admin';
  }
}

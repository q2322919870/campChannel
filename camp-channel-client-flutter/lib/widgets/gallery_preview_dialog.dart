import 'package:flutter/material.dart';
import '../canvas/gallery_3d_carousel.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../widgets/video_player_widget.dart';

/// A full-featured gallery item preview dialog with interaction buttons
/// (like, comment, share, delete/report) — mirrors PC client's GalleryPreview.vue.
class GalleryPreviewDialog extends StatefulWidget {
  final Gallery3DItem item;
  final VoidCallback? onDeleted;

  const GalleryPreviewDialog({
    super.key,
    required this.item,
    this.onDeleted,
  });

  static Future<void> show(BuildContext context, Gallery3DItem item, {VoidCallback? onDeleted}) {
    return showDialog(
      context: context,
      builder: (_) => GalleryPreviewDialog(item: item, onDeleted: onDeleted),
    );
  }

  @override
  State<GalleryPreviewDialog> createState() => _GalleryPreviewDialogState();
}

class _GalleryPreviewDialogState extends State<GalleryPreviewDialog> {
  final _apiClient = ApiClient();
  bool _isLiked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _showComment = false;
  bool _showShare = false;
  final _commentController = TextEditingController();
  final _shareUserIdController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  bool get _isOwner {
    final currentUserId = StorageService.getUserId();
    return currentUserId != null && widget.item.userId == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _shareUserIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchLikeStatus() async {
    try {
      final res = await _apiClient.get('/gallery/${widget.item.id}/like/status');
      final data = res.data;
      if (data != null && data['code'] == 200 && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _isLiked = d['hasLiked'] == true;
            _likeCount = d['likeCount'] is int
                ? d['likeCount'] as int
                : int.tryParse(d['likeCount']?.toString() ?? '0') ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchComments() async {
    try {
      final res = await _apiClient.get('/gallery/${widget.item.id}/comments');
      final data = res.data;
      if (data != null && data['code'] == 200 && data['data'] is List) {
        final list = (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) {
          setState(() {
            _comments = list;
            _commentCount = list.length;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    try {
      final res = await _apiClient.post('/gallery/${widget.item.id}/like');
      final data = res.data;
      if (data != null && data['code'] == 200 && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _isLiked = d['liked'] == true;
            _likeCount = d['likeCount'] is int
                ? d['likeCount'] as int
                : int.tryParse(d['likeCount']?.toString() ?? '0') ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    try {
      final res = await _apiClient.post(
        '/gallery/${widget.item.id}/comment',
        data: {'content': content},
      );
      final data = res.data;
      if (data != null && data['code'] == 200 && data['data'] != null) {
        final comment = Map<String, dynamic>.from(data['data'] as Map);
        if (mounted) {
          setState(() {
            _comments.insert(0, comment);
            _commentCount++;
            _commentController.clear();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论失败')),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确认删除这幅画？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await _apiClient.delete('/gallery/${widget.item.id}');
      final data = res.data;
      if (data != null && data['code'] == 200) {
        widget.onDeleted?.call();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除失败')),
        );
      }
    }
  }

  Future<void> _handleReport() async {
    try {
      await _apiClient.post('/reports', data: {
        'targetType': 'gallery',
        'targetId': widget.item.id,
        'reason': '违规画作举报',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报已提交')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报失败')),
        );
      }
    }
  }

  Future<void> _shareToUser() async {
    final userIdStr = _shareUserIdController.text.trim();
    if (userIdStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户ID')),
      );
      return;
    }
    try {
      await _apiClient.post(
        '/gallery/${widget.item.id}/share',
        data: {'targetUserId': int.tryParse(userIdStr) ?? 0},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已分享')),
        );
        setState(() {
          _showShare = false;
          _shareUserIdController.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final item = widget.item;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 800),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: SingleChildScrollView(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Media preview (constrained height)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.isVideo
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: InlineVideoPlayer(videoUrl: item.videoUrl!, autoPlay: true),
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 350),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 200,
                              child: Center(child: Text('图片加载失败')),
                            ),
                          ),
                        ),
                ),
              ),

              // Info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  // Author row
                  Row(
                    children: [
                      if (item.avatar != null && item.avatar!.isNotEmpty)
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(item.avatar!),
                        )
                      else
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primary,
                          child: Text(
                            (item.username ?? '?').characters.first,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        item.username ?? '用户',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  if (item.title != null && item.title!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Interaction buttons row
                  Row(
                    children: [
                      // Like button
                      _ActionButton(
                        icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                        label: '$_likeCount',
                        color: _isLiked ? Colors.pink : null,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 8),
                      // Comment button
                      _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '$_commentCount',
                        onTap: () => setState(() => _showComment = !_showComment),
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      _ActionButton(
                        icon: Icons.share_outlined,
                        onTap: () => setState(() => _showShare = !_showShare),
                      ),
                      const Spacer(),
                      // Delete or Report
                      if (_isOwner)
                        _ActionButton(
                          icon: Icons.delete_outline,
                          label: '删除',
                          color: Colors.red,
                          onTap: _handleDelete,
                        )
                      else
                        _ActionButton(
                          icon: Icons.flag_outlined,
                          label: '举报',
                          color: Colors.orange,
                          onTap: _handleReport,
                        ),
                    ],
                  ),

                  // Comment section
                  if (_showComment) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: '写评论...',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: const Text('发送'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: Text('暂无评论', style: TextStyle(fontSize: 12, color: Colors.grey))),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['username']?.toString() ?? '用户',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.primary, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      c['content']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],

                  // Share section
                  if (_showShare) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _shareUserIdController,
                            decoration: const InputDecoration(
                              hintText: '输入目标用户ID',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _shareToUser,
                          child: const Text('分享'),
                        ),
                      ],
                    ),
                  ],
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!, style: TextStyle(fontSize: 13, color: color ?? Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}


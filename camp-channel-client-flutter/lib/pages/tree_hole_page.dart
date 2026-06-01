import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../canvas/fog_shader.dart';

/// Tree Hole / Confession Wall page.
/// Anonymous posts displayed with fog/mist shader - drag to reveal.
class TreeHolePage extends StatefulWidget {
  const TreeHolePage({super.key});

  @override
  State<TreeHolePage> createState() => _TreeHolePageState();
}

class _TreeHolePageState extends State<TreeHolePage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final TextEditingController _contentCtrl = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _markPostRevealed(int postId) async {
    // 调用服务器API保存解开状态，实现跨平台同步
    try {
      await _apiClient.post('/posts/$postId/reveal');
      print('[TreeHole] ✅ Saved reveal state for post $postId to server');
    } catch (e) {
      print('[TreeHole] ❌ Failed to save reveal state: $e');
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/posts/tree-hole');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = (result['data'] is List)
            ? result['data'] as List
            : (result['data']['records'] as List? ?? []);
        if (mounted) {
          setState(() {
            _posts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  Future<void> _submitConfession() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final response = await _apiClient.post('/posts', data: {
        'content': content,
        'isAnonymous': true,
        'channelId': null,
      });
      final result = response.data;
      if (result != null && result['code'] == 200) {
        _contentCtrl.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('匿名告白已发布')),
          );
          await _fetchPosts();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '发布失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                '树洞告白墙',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              child: _posts.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, size: 64,
                                    color: colorScheme.primary.withOpacity(0.3)),
                                const SizedBox(height: 16),
                                Text('还没有匿名告白，成为第一个吧',
                                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return _buildConfessionCard(post, index, colorScheme);
                      },
                    ),
            ),
      bottomNavigationBar: _buildComposeBar(colorScheme),
    );
  }

  Widget _buildConfessionCard(Map<String, dynamic> post, int index, ColorScheme colorScheme) {
    final content = post['content']?.toString() ?? '';
    final time = post['createTime']?.toString() ?? '';
    final likeCount = post['likeCount'] ?? 0;
    final postId = post['id'] is int ? post['id'] as int : int.tryParse(post['id']?.toString() ?? '') ?? index;
    // 使用服务器返回的isRevealed字段
    final isRevealed = post['isRevealed'] == true;
    final theme = Theme.of(context);
    
    if (isRevealed) {
      print('[TreeHole] 📝 Post $postId: REVEALED (showing content directly)');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isRevealed
              ? GestureDetector(
                  onLongPress: () => _showReportDialog(postId, colorScheme),
                  child: _buildCardContent(content, time, likeCount, colorScheme),
                )
              : FogRevealWidget(
                  fogColor: Theme.of(context).cardColor,
                  accentColor: colorScheme.primary,
                  fogOpacity: 1.0,
                  brushRadius: 40.0,
                  initiallyRevealed: isRevealed,
                  onFullyRevealed: () => _markPostRevealed(postId),
                  child: _buildCardContent(content, time, likeCount, colorScheme),
                ),
        ),
      ),
    );
  }

  Widget _buildCardContent(
    String content,
    String time,
    int likeCount,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.03),
            colorScheme.secondary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '匿名',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (likeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, size: 12, color: colorScheme.error),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: colorScheme.onSurface,
            ),
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(
                  time.substring(0, time.length > 16 ? 16 : time.length),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposeBar(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _contentCtrl,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: '写下你的匿名告白...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _isPosting
              ? const SizedBox(
                  width: 44, height: 44,
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : GestureDetector(
                  onTap: _submitConfession,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
        ],
      ),
    );
  }

  void _showReportDialog(int postId, ColorScheme colorScheme) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_outlined, color: colorScheme.error),
            const SizedBox(width: 8),
            const Text('举报告白'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '举报后管理员会审核该内容，如确认违规将被下架。',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '请输入举报原因（选填）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitReport(postId, reasonController.text.trim());
            },
            child: const Text('提交举报'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(int postId, String reason) async {
    try {
      final response = await _apiClient.post('/reports', data: {
        'targetType': 'post',
        'targetId': postId,
        'reason': reason.isEmpty ? '内容违规' : reason,
      });
      
      final result = response.data;
      if (result != null && result['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('举报成功，我们会尽快处理'),
                ],
              ),
              backgroundColor: Colors.white,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '举报失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('举报失败: $e')),
        );
      }
    }
  }
}

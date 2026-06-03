import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class DraftListPage extends StatefulWidget {
  const DraftListPage({super.key});

  @override
  State<DraftListPage> createState() => _DraftListPageState();
}

class _DraftListPageState extends State<DraftListPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrafts();
  }

  Future<void> _fetchDrafts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/drafts');
      if (res.data['code'] == 200 && res.data['data'] is List) {
        setState(() => _drafts = List<Map<String, dynamic>>.from(res.data['data']));
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteDraft(int id) async {
    try {
      await _apiClient.delete('/drafts/$id');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('草稿已删除')));
      _fetchDrafts();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
    }
  }

  Future<void> _publishDraft(int id) async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.post('/drafts/$id/publish');
      if (res.data['code'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('帖子已发布')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? '发布失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除草稿'),
        content: const Text('确定要删除这个草稿吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deleteDraft(id); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('我的草稿')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.drafts_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('暂无草稿', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDrafts,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      final id = draft['id'] as int;
                      final content = draft['content']?.toString() ?? '';
                      final channelName = draft['channelName']?.toString() ?? '未选择频道';
                      final updateTime = draft['updateTime']?.toString().substring(0, 16).replaceFirst('T', ' ') ?? '';
                      final topic = draft['topic']?.toString() ?? '';

                      return Container(
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
                                Icon(Icons.tag, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(channelName, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600)),
                                if (topic.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(topic, style: TextStyle(fontSize: 11, color: colorScheme.onSecondaryContainer)),
                                  ),
                                ],
                                const Spacer(),
                                Text(updateTime, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.4))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              content.isEmpty ? '(空内容)' : content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(id),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('删除'),
                                  style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _publishDraft(id),
                                  icon: const Icon(Icons.send, size: 18),
                                  label: const Text('发布'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

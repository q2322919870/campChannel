import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class ChannelSearchPage extends StatefulWidget {
  const ChannelSearchPage({super.key});

  @override
  State<ChannelSearchPage> createState() => _ChannelSearchPageState();
}

class _ChannelSearchPageState extends State<ChannelSearchPage> {
  final _searchController = TextEditingController();
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _allChannels = [];
  List<Map<String, dynamic>> _filteredChannels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChannels();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/channels/search');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _allChannels = list.map((e) => e as Map<String, dynamic>).toList();
            _filteredChannels = List.from(_allChannels);
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChannels = _allChannels.where((c) =>
        (c['name']?.toString() ?? '').toLowerCase().contains(query) ||
        (c['description']?.toString() ?? '').toLowerCase().contains(query)
      ).toList();
    });
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool creating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('创建频道'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '频道名称',
                  hintText: '输入频道名称',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '频道描述',
                  hintText: '描述这个频道...',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: creating
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;
                      setDialogState(() => creating = true);
                      try {
                        await _apiClient.post('/channels', data: {
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _fetchChannels();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('频道创建成功'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } on DioException catch (e) {
                        setDialogState(() => creating = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.response?.data?['message'] ?? '创建失败'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索频道...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurface.withOpacity(0.4)),
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
            onPressed: _showCreateChannelDialog,
            tooltip: '创建频道',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredChannels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tag, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('未找到频道', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showCreateChannelDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('创建频道'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredChannels.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              '发现 ${_filteredChannels.length} 个频道',
                              style: theme.textTheme.bodySmall,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showCreateChannelDialog,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('创建', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    }
                    final channel = _filteredChannels[index - 1];
                    return _buildChannelCard(context, channel);
                  },
                ),
    );
  }

  Widget _buildChannelCard(BuildContext context, Map<String, dynamic> channel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = channel['name'] ?? '未命名';
    final description = channel['description'] as String? ?? '';
    final memberCount = channel['memberCount'] ?? channel['members'] ?? 0;
    final postCount = channel['postCount'] ?? channel['posts'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary.withOpacity(0.2), colorScheme.secondary.withOpacity(0.15)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.tag, color: colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      '${memberCount} 成员 · ${postCount} 帖子',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('加入', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

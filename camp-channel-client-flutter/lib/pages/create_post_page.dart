import 'package:flutter/material.dart';
import 'package:camp_channel_client_flutter/core/network/api_client.dart';
import '../core/services/storage_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _topicController = TextEditingController();
  final _mentionController = TextEditingController();
  String? _selectedChannelId;
  final List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isSavingDraft = false;
  List<Map<String, dynamic>> _channels = [];

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _topicController.dispose();
    _mentionController.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels() async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/channels/my');
      if (res.data['code'] == 200 && res.data['data'] is List) {
        setState(() => _channels = List<Map<String, dynamic>>.from(res.data['data']));
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_selectedChannelId == null || _contentController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      String finalContent = _contentController.text.trim();
      if (_topicController.text.trim().isNotEmpty) {
        final t = _topicController.text.trim();
        finalContent += '\n${t.startsWith('#') ? t : '#$t'}${t.endsWith('#') ? '' : '#'}';
      }
      if (_mentionController.text.trim().isNotEmpty) {
        finalContent += ' ${_mentionController.text.trim()}';
      }
      final apiClient = ApiClient();
      final res = await apiClient.post('/posts', data: {
        'channelId': int.parse(_selectedChannelId!),
        'content': finalContent,
        'images': _imageUrls.isEmpty ? null : _imageUrls,
      });
      if (res.data['code'] == 200 && mounted) Navigator.pop(context);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }
    setState(() => _isSavingDraft = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.post('/drafts', data: {
        'channelId': _selectedChannelId != null ? int.parse(_selectedChannelId!) : null,
        'content': _contentController.text.trim(),
        'images': _imageUrls.isEmpty ? null : _imageUrls.join(','),
        'topic': _topicController.text.trim().isNotEmpty ? _topicController.text.trim() : null,
      });
      if (res.data['code'] == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('草稿已保存')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
    if (mounted) setState(() => _isSavingDraft = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('发布帖子'), actions: [
        TextButton.icon(
          onPressed: _isSavingDraft ? null : _saveDraft,
          icon: const Icon(Icons.drafts_outlined, size: 18),
          label: Text(_isSavingDraft ? '保存中...' : '存草稿', style: TextStyle(color: colorScheme.secondary)),
        ),
        TextButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(_isLoading ? '发布中...' : '发布', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Text((StorageService.getUsername() ?? '?').isNotEmpty ? (StorageService.getUsername() ?? '?')[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary)),
              ),
              const SizedBox(width: 10),
              Text(StorageService.getUsername() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedChannelId,
            decoration: const InputDecoration(labelText: '选择频道', border: OutlineInputBorder()),
            items: _channels.map((ch) => DropdownMenuItem(value: ch['id'].toString(), child: Text(ch['name'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedChannelId = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: '内容 *', hintText: '写点什么...', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(labelText: '话题（选填）', hintText: '#话题名称#', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mentionController,
            decoration: const InputDecoration(labelText: '@ 提及（选填）', hintText: '@用户名', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';

class ChannelCreatePage extends StatefulWidget {
  const ChannelCreatePage({super.key});

  @override
  State<ChannelCreatePage> createState() => _ChannelCreatePageState();
}

class _ChannelCreatePageState extends State<ChannelCreatePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _apiClient = ApiClient();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createChannel() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入频道名称')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final response = await _apiClient.post('/channels', data: {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty 
            ? null 
            : _descController.text.trim(),
      });

      final result = response.data;
      if (mounted) {
        if (result != null && result['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('频道创建成功')),
          );
          Navigator.pop(context, true); // Return success to refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '创建失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建失败，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建频道'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createChannel,
            child: Text(
              _isCreating ? '创建中...' : '创建',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '创建频道后，您将成为频道管理员，可以邀请其他成员加入',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Channel name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '频道名称 *',
              hintText: '给你的频道起个名字',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.channel),
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          // Description
          TextField(
            controller: _descController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: '频道描述（选填）',
              hintText: '介绍一下这个频道的用途和规则...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 24),
          // Creator info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    (StorageService.getUsername() ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StorageService.getUsername() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '频道创建者',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

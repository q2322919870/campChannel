import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrateEnabled = false;
  bool _emailNotifyEnabled = false;
  String _serverAddress = '';
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _apiClient.get('/users/me');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _emailNotifyEnabled = data['emailNotify'] == true;
          });
        }
      }
    } catch (_) {}
    // 读取已保存的服务器地址
    final saved = StorageService.getApiBaseUrl();
    if (saved != null) {
      setState(() => _serverAddress = saved);
    }
  }

  Future<void> _toggleEmailNotify(bool v) async {
    try {
      await _apiClient.put('/users/me', data: {'emailNotify': v ? 1 : 0});
      setState(() => _emailNotifyEnabled = v);
    } catch (_) {}
  }

  Future<void> _showServerAddressDialog() async {
    final controller = TextEditingController(text: _serverAddress);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入后端服务器地址，例如：'),
            const SizedBox(height: 4),
            const Text('http://192.168.1.100:8080/api',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://192.168.110.126:8080/api',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await StorageService.saveApiBaseUrl(result);
      ApiClient.reset();
      if (mounted) setState(() => _serverAddress = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, '通知设置'),
          const SizedBox(height: 8),
          _buildSwitchTile(context, '推送通知', '接收新消息、评论等推送', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          _buildSwitchTile(context, '声音', '新消息提醒声音', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
          _buildSwitchTile(context, '震动', '新消息震动提醒', _vibrateEnabled, (v) => setState(() => _vibrateEnabled = v)),
          const SizedBox(height: 12),
          _buildSwitchTile(context, '邮件通知', '接收邮件推送通知', _emailNotifyEnabled, _toggleEmailNotify),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '隐私设置'),
          const SizedBox(height: 8),
          _buildMenuTile(context, '在线状态', '所有人可见'),
          _buildMenuTile(context, '好友验证', '需要验证'),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '设备'),
          const SizedBox(height: 8),
          _buildMenuTile(context, '设备管理', '管理登录设备', onTap: () => Navigator.pushNamed(context, '/device_management')),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '服务器'),
          const SizedBox(height: 8),
          _buildMenuTile(context, '服务器地址',
              _serverAddress.isEmpty ? '未设置（使用默认）' : _serverAddress,
              onTap: _showServerAddressDialog),
          const SizedBox(height: 24),
          _buildSectionHeader(context, '关于'),
          const SizedBox(height: 8),
          _buildMenuTile(context, '版本号', 'v1.0.0'),
          _buildMenuTile(context, '检查更新', '当前已是最新版本'),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Camp Channel v1.0.0\n广东机电职业技术学院',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: SwitchListTile(
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, String subtitle, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }
}

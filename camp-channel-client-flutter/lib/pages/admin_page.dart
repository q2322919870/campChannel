import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final _apiClient = ApiClient();

  final List<_AdminSection> _sections = [
    _AdminSection('仪表盘', Icons.dashboard_outlined, Icons.dashboard, [
      {'label': '总用户数', 'value': '1,280', 'icon': Icons.people, 'color': Colors.blue},
      {'label': '今日活跃', 'value': '356', 'icon': Icons.trending_up, 'color': Colors.green},
      {'label': '帖子总数', 'value': '4,520', 'icon': Icons.article, 'color': Colors.orange},
      {'label': '举报处理', 'value': '3', 'icon': Icons.flag, 'color': Colors.red},
    ]),
    _AdminSection('用户管理', Icons.people_outline, Icons.people, []),
    _AdminSection('内容审核', Icons.verified_outlined, Icons.verified, []),
    _AdminSection('发布公告', Icons.campaign_outlined, Icons.campaign, []),
    _AdminSection('系统设置', Icons.settings_outlined, Icons.settings, []),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.admin_panel_settings, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('管理员后台'),
          ],
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(right: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
            ),
            child: Column(
              children: List.generate(_sections.length, (index) {
                final section = _sections[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isSelected ? section.activeIcon : section.icon,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(context);
      case 3:
        return _buildAnnouncement(context);
      default:
        return _buildPlaceholder(context);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stats = _sections[0].stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('运营概览', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: stats.length,
            itemBuilder: (_, index) {
              final stat = stats[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (stat['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
                        ),
                        const Spacer(),
                        Icon(Icons.more_horiz, color: colorScheme.onSurface.withOpacity(0.3), size: 18),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      stat['value'] as String,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label'] as String,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncement(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool publishing = false;

    return StatefulBuilder(
      builder: (ctx, setLocalState) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('发布公告', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('公告将推送给所有用户', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '公告标题',
                hintText: '输入公告标题...',
                prefixIcon: const Icon(Icons.title),
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '公告内容',
                hintText: '输入公告详细内容...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 150),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: publishing
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('请填写公告标题')),
                          );
                          return;
                        }
                        setLocalState(() => publishing = true);
                        try {
                          await _apiClient.post('/admin/announcement', data: {
                            'title': titleController.text.trim(),
                            'content': contentController.text.trim(),
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('公告发布成功'),
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            titleController.clear();
                            contentController.clear();
                          }
                        } on DioException catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(e.response?.data?['message'] ?? '发布失败'),
                                backgroundColor: colorScheme.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) setLocalState(() => publishing = false);
                        }
                      },
                icon: publishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(publishing ? '发布中...' : '发布公告'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final section = _sections[_selectedIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(section.activeIcon, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            '${section.name}模块',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '功能开发中...',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AdminSection {
  final String name;
  final IconData icon;
  final IconData activeIcon;
  final List<Map<String, dynamic>> stats;

  _AdminSection(this.name, this.icon, this.activeIcon, this.stats);
}

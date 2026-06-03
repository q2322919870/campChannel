import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;
  String _activeCategory = ''; // '' = all, 'system', 'interaction', 'chat'
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'value': '', 'label': '全部', 'icon': Icons.notifications_outlined},
    {'value': 'system', 'label': '系统', 'icon': Icons.info_outline},
    {'value': 'interaction', 'label': '互动', 'icon': Icons.favorite_outline},
    {'value': 'chat', 'label': '聊天', 'icon': Icons.chat_bubble_outline},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeCategory = _categories[_tabController.index]['value'] as String;
        });
        _fetchNotifications();
      }
    });
    _fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{'page': 1, 'size': 50};
      if (_activeCategory.isNotEmpty) {
        params['category'] = _activeCategory;
      }
      final response = await _apiClient.get('/notifications/history', queryParameters: params);
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _notifications = list.map((e) => e as Map<String, dynamic>).toList();
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

  Future<void> _markAllAsRead() async {
    try {
      await _apiClient.post('/notifications/read-all');
      await _fetchNotifications();
    } catch (_) {}
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.chat_bubble;
      case 'follow': return Icons.person_add;
      case 'mention': return Icons.alternate_email;
      case 'friend_request': return Icons.person_add_alt;
      case 'channel': return Icons.group;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications;
    }
  }

  Color _getTypeColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'like': return Colors.redAccent;
      case 'comment': return colorScheme.primary;
      case 'follow': return Colors.green;
      case 'mention': return Colors.deepPurple;
      case 'friend_request': return Colors.blue;
      case 'channel': return Colors.teal;
      case 'system': return Colors.grey;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('通知'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('全部已读', style: TextStyle(color: colorScheme.primary, fontSize: 13)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: _categories.map((cat) => Tab(
            icon: Icon(cat['icon'] as IconData, size: 18),
            text: cat['label'] as String,
          )).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text('暂无通知', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isUnread = !(notif['isRead'] == 1 || notif['read'] == true);
                        final type = notif['type']?.toString() ?? 'system';
                        final category = notif['category']?.toString() ?? 'system';
                        final user = notif['username']?.toString() ?? notif['user']?.toString() ?? '';
                        final content = notif['content']?.toString() ?? '';
                        final time = notif['createTime']?.toString() ?? notif['createdAt']?.toString() ?? '';

                        final icon = _getTypeIcon(type);
                        final iconColor = _getTypeColor(type, colorScheme);
                        final relatedId = notif['relatedId']?.toString();

                        return GestureDetector(
                          onTap: () async {
                            final notifId = notif['id'];
                            if (notifId != null && isUnread) {
                              try {
                                await _apiClient.post('/notifications/$notifId/read');
                              } catch (_) {}
                            }
                            if (relatedId != null && (type == 'mention' || type == 'comment' || type == 'like')) {
                              Navigator.pushNamed(context, '/post_detail', arguments: {'id': int.tryParse(relatedId)});
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUnread ? colorScheme.primary.withOpacity(0.05) : theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread ? colorScheme.primary.withOpacity(0.1) : colorScheme.onSurface.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                style: theme.textTheme.bodyMedium,
                                                children: [
                                                  if (user.isNotEmpty)
                                                    TextSpan(
                                                      text: '$user ',
                                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                  TextSpan(text: content),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (time.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _formatTime(time),
                                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
      return timeStr;
    }
  }
}

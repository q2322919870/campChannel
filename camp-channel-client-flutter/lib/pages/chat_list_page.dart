import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/websocket_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _chats = [];
  Map<int, bool> _onlineMap = {};
  bool _isLoading = true;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _onlineSub;
  StreamSubscription<Map<String, dynamic>>? _readReceiptSub;

  @override
  void initState() {
    super.initState();
    _fetchChats();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchChats());
    _listenOnlineStatus();
    _listenReadReceipt();
  }

  void _listenOnlineStatus() {
    final ws = WebSocketService();
    _onlineSub = ws.onlineStatusStream.listen((status) {
      if (!mounted) return;
      final userId = status['userId'] is int
          ? status['userId'] as int
          : int.tryParse(status['userId']?.toString() ?? '');
      final online = status['online'] == true;
      if (userId != null && userId > 0) {
        setState(() {
          _onlineMap[userId] = online;
        });
      }
    });
  }

  void _listenReadReceipt() {
    final ws = WebSocketService();
    _readReceiptSub = ws.readReceiptStream.listen((_) {
      if (!mounted) return;
      _fetchChats();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _onlineSub?.cancel();
    _readReceiptSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/chat/conversations/with-unread');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _chats = list.map((e) => e as Map<String, dynamic>).toList();
            _isLoading = false;
          });
          _fetchOnlineStatus();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOnlineStatus() async {
    final userIds = _chats.map((c) {
      final id = c['id'] ?? c['userId'] ?? 0;
      return id is int ? id : int.tryParse(id.toString()) ?? 0;
    }).where((id) => id > 0).toList();
    if (userIds.isEmpty) return;
    try {
      final response = await _apiClient.get('/chat/online/batch', queryParameters: {'userIds': userIds.join(',')});
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _onlineMap = data.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v == true));
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _markAsRead(Map<String, dynamic> chat) async {
    final friendId = chat['id'] ?? 0;
    try {
      await _apiClient.post('/chat/read-all/$friendId');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => Navigator.pushNamed(context, '/friend_search'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('暂无消息', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                      const SizedBox(height: 8),
                      Text('去添加好友开始聊天吧', style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.3))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) => _buildChatItem(context, _chats[index]),
                ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = chat['username']?.toString() ?? '未知';
    final lastMsg = chat['lastMsg']?.toString() ?? chat['lastMessage']?.toString() ?? '';
    final time = chat['time']?.toString() ?? chat['updatedAt']?.toString() ?? '';
    final unread = chat['unread'] ?? chat['unreadCount'] ?? 0;
    final avatarUrl = chat['avatar'] as String?;
    final displayAvatar = ApiClient.processImageUrl(avatarUrl);
    final friendId = chat['id'] is int ? chat['id'] as int : int.tryParse(chat['id']?.toString() ?? '');
    final isOnline = friendId != null ? (_onlineMap[friendId] ?? false) : false;

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        await _markAsRead(chat);
        if (!mounted) return;
        navigator.pushNamed('/chat_detail', arguments: {
            'friendId': friendId ?? 0,
            'friendName': name,
            'friendAvatar': avatarUrl,
          });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: displayAvatar.isNotEmpty
                        ? Image.network(
                            displayAvatar,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2.5),
                      ),
                    ),
                  ),
                if (unread > 0)
                  Positioned(
                    right: isOnline ? -6 : -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.cardColor, width: 2),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          _formatTime(time),
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
      if (diff.inDays < 1) return '昨天';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return timeStr;
    }
  }
}

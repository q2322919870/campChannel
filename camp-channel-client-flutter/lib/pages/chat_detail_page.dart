import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../core/services/websocket_service.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  final _apiClient = ApiClient();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  int? _friendId;
  String _friendName = '聊天';
  String? _friendAvatar;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;
  StreamSubscription<Map<String, dynamic>>? _onlineSub;
  bool _isFriendOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initArgs());
  }

  void _initArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _friendId = args['friendId'] is int
          ? args['friendId'] as int
          : int.tryParse(args['friendId']?.toString() ?? '');
      _friendName = args['friendName']?.toString() ?? '聊天';
      _friendAvatar = args['friendAvatar'] as String?;
    }
    if (_friendId != null && _friendId! > 0) {
      _fetchFriendInfo();
      _fetchOnlineStatus();
      _listenWebSocket();
      _listenOnlineStatus();
      _fetchHistory();
      _markAsRead();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFriendInfo() async {
    try {
      final response = await _apiClient.get('/users/$_friendId');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _friendAvatar = data['avatar'] as String?;
            if (data['username'] != null) {
              _friendName = data['username'] as String;
            }
          });
        }
      }
    } catch (_) {}
  }

  void _listenWebSocket() {
    final ws = WebSocketService();
    final myUserId = StorageService.getUserId();
    _msgSub = ws.messageStream.listen((msg) {
      if (!mounted) return;
      final senderId = msg['senderId'] is int
          ? msg['senderId'] as int
          : int.tryParse(msg['senderId']?.toString() ?? '');
      final receiverId = msg['receiverId'] is int
          ? msg['receiverId'] as int
          : int.tryParse(msg['receiverId']?.toString() ?? '');
      // Only show messages from current chat partner or self
      if ((senderId == _friendId || senderId == myUserId) &&
          (receiverId == _friendId || receiverId == myUserId)) {
        setState(() {
          // Avoid duplicates
          final msgId = msg['id']?.toString();
          if (msgId != null) {
            _messages.removeWhere((m) => m['id']?.toString() == msgId);
          }
          // Append at end and maintain sort order
          _messages.add(msg);
          _messages.sort((a, b) {
            final ta = (a['createTime'] ?? a['createdAt'] ?? '')?.toString() ?? '';
            final tb = (b['createTime'] ?? b['createdAt'] ?? '')?.toString() ?? '';
            return ta.compareTo(tb);
          });
        });
      }
    });
    _readSub = ws.readReceiptStream.listen((msg) {
      if (!mounted) return;
      final friendId = msg['friendId'] is int
          ? msg['friendId'] as int
          : int.tryParse(msg['friendId']?.toString() ?? '');
      if (friendId == _friendId) {
        setState(() {
          for (var m in _messages) {
            // Only mark sent messages as read
            if (m['senderId'] == myUserId) {
              m['status'] = 'READ';
              m['isRead'] = 1;
            }
          }
        });
      }
    });
  }

  void _listenOnlineStatus() {
    final ws = WebSocketService();
    _onlineSub = ws.onlineStatusStream.listen((status) {
      if (!mounted) return;
      final userId = status['userId'] is int
          ? status['userId'] as int
          : int.tryParse(status['userId']?.toString() ?? '');
      final online = status['online'] == true;
      if (userId == _friendId) {
        setState(() {
          _isFriendOnline = online;
        });
      }
    });
  }

  Future<void> _fetchOnlineStatus() async {
    if (_friendId == null || _friendId! <= 0) return;
    try {
      final response = await _apiClient.get('/chat/online/batch',
          queryParameters: {'userIds': '$_friendId'});
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _isFriendOnline = data['$_friendId'] == true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHistory() async {
    if (_friendId == null) return;
    try {
      final response = await _apiClient.get('/chat/history/$_friendId', queryParameters: {
        'page': '1',
        'size': '50',
      });
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            // Merge: keep existing message IDs to avoid overwriting WS-added messages
            final existingIds = _messages.map((m) => m['id']?.toString()).toSet();
            for (final item in list) {
              final m = item as Map<String, dynamic>;
              final id = m['id']?.toString();
              if (id != null && !existingIds.contains(id)) {
                _messages.add(m);
              }
            }
            // Sort by creation time
            _messages.sort((a, b) {
              final ta = (a['createTime'] ?? a['createdAt'] ?? '')?.toString() ?? '';
              final tb = (b['createTime'] ?? b['createdAt'] ?? '')?.toString() ?? '';
              return ta.compareTo(tb);
            });
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

  Future<void> _markAsRead() async {
    if (_friendId == null) return;
    try {
      await _apiClient.post('/chat/read-all/$_friendId');
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _friendId == null) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final response = await _apiClient.post('/chat/messages/send', data: {
        'receiverId': _friendId,
        'content': content,
      });
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        if (mounted) {
          setState(() {
            _messages.add(result['data'] as Map<String, dynamic>);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'senderId': StorageService.getUserId(),
            'content': content,
            'status': 'FAILED',
            'createdAt': DateTime.now().toIso8601String(),
          });
        });
      }
    }
  }

  bool _canRecall(Map<String, dynamic> msg) {
    final timeStr = msg['createTime']?.toString() ?? msg['createdAt']?.toString() ?? '';
    try {
      final dt = DateTime.parse(timeStr);
      return DateTime.now().difference(dt).inMilliseconds < 120000;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pollTimer?.cancel();
    _msgSub?.cancel();
    _readSub?.cancel();
    _onlineSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _friendAvatar != null && _friendAvatar!.isNotEmpty
                    ? Image.network(
                        ApiClient.processImageUrl(_friendAvatar),
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _friendName.isNotEmpty ? _friendName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _friendName.isNotEmpty ? _friendName[0] : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_friendName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isFriendOnline ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isFriendOnline ? '在线' : '离线',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isFriendOnline ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final senderId = msg['senderId'] is int
                          ? msg['senderId'] as int
                          : int.tryParse(msg['senderId']?.toString() ?? '');
                      final isMe = senderId == StorageService.getUserId();
                      return _buildMessageBubble(context, msg, isMe);
                    },
                  ),
          ),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> msg, bool isMe) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final content = msg['content']?.toString() ?? '';
    // Determine read status: support both new integer status and old string status
    // New: 0=sending, 1=sent, 2=delivered, 3=read, 5=recalled
    // Old: isRead (0/1) + status string (SENDING/SENT/DELIVERED/READ)
    int statusInt = msg['status'] is int ? msg['status'] as int : 1;
    bool isRead = msg['isRead'] == 1 || statusInt == 3;
    String statusText;
    
    if (statusInt == 0) {
      statusText = 'SENDING';
    } else if (statusInt == 1) {
      statusText = 'SENT';
    } else if (statusInt == 2) {
      statusText = 'DELIVERED';
    } else if (statusInt == 3 || isRead) {
      statusText = 'READ';
    } else if (statusInt == 5) {
      statusText = 'RECALLED';
    } else {
      // Fallback to old string status
      statusText = msg['status']?.toString() ?? 'SENT';
    }
    
    final timeStr = msg['createTime']?.toString() ?? msg['createdAt']?.toString() ?? '';

    return GestureDetector(
      onLongPress: () {
        if (isMe && _canRecall(msg)) {
          _showRecallDialog(context, msg);
        }
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? colorScheme.primary : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: isMe ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeStr.isNotEmpty)
                    Text(
                      _formatTime(timeStr),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(statusText, colorScheme),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'SENDING':
        return SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: colorScheme.onSurface.withOpacity(0.4)),
        );
      case 'FAILED':
        return const Icon(Icons.error_outline, size: 12, color: Colors.redAccent);
      case 'READ':
        // Blue double check - read
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: colorScheme.primary),
            Icon(Icons.check, size: 12, color: colorScheme.primary),
          ],
        );
      case 'DELIVERED':
        // Gray double check - delivered
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: colorScheme.onSurface.withOpacity(0.4)),
            Icon(Icons.check, size: 12, color: colorScheme.onSurface.withOpacity(0.4)),
          ],
        );
      case 'RECALLED':
        return const Icon(Icons.undo, size: 12, color: Colors.orange);
      default:
        // SENT - single gray check
        return Icon(Icons.check, size: 12, color: colorScheme.onSurface.withOpacity(0.4));
    }
  }

  void _showRecallDialog(BuildContext context, Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('撤回消息'),
        content: const Text('是否撤回该消息？（2分钟内可撤回）'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _recallMessage(msg);
            },
            child: Text('撤回', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _recallMessage(Map<String, dynamic> msg) async {
    final msgId = msg['id'];
    if (msgId == null) return;
    try {
      await _apiClient.post('/chat/messages/$msgId/recall');
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id']?.toString() == msgId.toString());
        });
      }
    } catch (_) {}
  }

  Widget _buildInputBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: colorScheme.onSurface.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
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
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }
}

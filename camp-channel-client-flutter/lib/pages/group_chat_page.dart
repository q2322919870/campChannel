import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../core/services/websocket_service.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final _messageController = TextEditingController();
  final _apiClient = ApiClient();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  int? _channelId;
  String _channelName = '群聊';
  StreamSubscription<Map<String, dynamic>>? _msgSub;
  List<Map<String, dynamic>> _members = [];
  bool _isAdmin = false;
  bool _showMembers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initArgs());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _msgSub?.cancel();
    super.dispose();
  }

  void _initArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _channelId = args['channelId'] is int
          ? args['channelId'] as int
          : int.tryParse(args['channelId']?.toString() ?? '');
      _channelName = args['channelName']?.toString() ?? '群聊';
    }
    if (_channelId != null && _channelId! > 0) {
      _listenWebSocket();
      _fetchHistory();
      _fetchMembers();
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _listenWebSocket() {
    final ws = WebSocketService();
    _msgSub = ws.messageStream.listen((msg) {
      if (!mounted) return;
      final msgType = msg['type']?.toString();
      if (msgType == 'new_group_message') {
        final msgChannelId = msg['channelId'] is int
            ? msg['channelId'] as int
            : int.tryParse(msg['channelId']?.toString() ?? '');
        if (msgChannelId == _channelId) {
          setState(() {
            final msgId = msg['id']?.toString();
            if (msgId != null) {
              _messages.removeWhere((m) => m['id']?.toString() == msgId);
            }
            _messages.add(msg);
            _messages.sort((a, b) {
              final ta = (a['createTime'] ?? '').toString();
              final tb = (b['createTime'] ?? '').toString();
              return ta.compareTo(tb);
            });
          });
        }
      }
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _apiClient.get(
        '/group-messages/$_channelId',
        queryParameters: {'page': 1, 'size': 50},
      );
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(list.map((e) => e as Map<String, dynamic>).toList());
            _messages.sort((a, b) {
              final ta = (a['createTime'] ?? '').toString();
              final tb = (b['createTime'] ?? '').toString();
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      final response = await _apiClient.post('/group-messages', data: {
        'channelId': _channelId,
        'content': content,
        'msgType': 1,
      });
      final result = response.data;
      if (result != null && result['code'] == 200) {
        // Message will be added via WebSocket
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _recallMessage(Map<String, dynamic> msg) async {
    final msgId = msg['id'];
    if (msgId == null) return;
    try {
      final response = await _apiClient.delete('/group-messages/$msgId');
      final result = response.data;
      if (result != null && result['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('消息已撤回')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('撤回失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchMembers() async {
    try {
      final response = await _apiClient.get('/channels/$_channelId/members');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        final myUserId = StorageService.getUserId();
        if (mounted) {
          setState(() {
            _members = list.map((e) => e as Map<String, dynamic>).toList();
            final myMember = _members.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m!['userId'] == myUserId,
              orElse: () => null,
            );
            _isAdmin = myMember != null &&
                (myMember['role'] == 'owner' || myMember['role'] == 'admin');
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleMute(int userId, bool muted) async {
    try {
      final response = await _apiClient.post(
        '/channels/$_channelId/members/$userId/mute',
        data: {'muted': muted},
      );
      final result = response.data;
      if (result != null && result['code'] == 200) {
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myUserId = StorageService.getUserId();

    return Scaffold(
      appBar: AppBar(
        title: Text(_channelName),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(_showMembers ? Icons.people : Icons.people_outline),
              tooltip: '成员管理',
              onPressed: () => setState(() => _showMembers = !_showMembers),
            ),
        ],
      ),
      body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                if (_showMembers && _isAdmin) _buildMembersPanel(context),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final senderId = msg['senderId'] is int
                          ? msg['senderId'] as int
                          : int.tryParse(msg['senderId']?.toString() ?? '');
                      final isMe = senderId == myUserId;
                      return _buildMessageBubble(context, msg, isMe, colorScheme);
                    },
                  ),
                ),
                _buildInputBar(context, colorScheme),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> msg,
    bool isMe,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    final content = msg['content']?.toString() ?? '';
    final username = msg['username']?.toString() ?? '未知用户';
    final status = msg['status'] ?? 1;
    final timeStr = msg['createTime']?.toString() ?? '';

    if (status == 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            isMe ? '你撤回了一条消息' : '$username 撤回了一条消息',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageContextMenu(context, msg, isMe);
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
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    username,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(timeStr),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageContextMenu(
      BuildContext context, Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.undo),
              title: const Text('撤回消息'),
              onTap: () {
                Navigator.pop(ctx);
                _recallMessage(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: colorScheme.primary,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dateTime = DateTime.parse(timeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  Widget _buildMembersPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myUserId = StorageService.getUserId();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '频道成员 (${_members.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '长按成员管理禁言',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                final userId = member['userId'] is int
                    ? member['userId'] as int
                    : int.tryParse(member['userId']?.toString() ?? '') ?? 0;
                final username = member['username']?.toString() ?? '用户';
                final role = member['role']?.toString() ?? 'member';
                final isMuted = member['isMuted'] == 1 || member['isMuted'] == true;
                final isOwner = role == 'owner';
                final roleLabel = isOwner ? '频道主' : (role == 'admin' ? '管理员' : '成员');

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    username,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '$roleLabel${isMuted ? ' · 已禁言' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isMuted
                          ? Colors.orange
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  trailing: userId == myUserId || isOwner
                      ? null
                      : IconButton(
                          icon: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            size: 20,
                            color: isMuted ? Colors.orange : colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: () => _toggleMute(userId, !isMuted),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

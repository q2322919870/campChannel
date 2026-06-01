import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../widgets/user_card.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  Map<int, bool> _onlineMap = {};
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchOnlineStatus();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchFriends(), _fetchPendingRequests()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchOnlineStatus() async {
    final userIds = _friends.map((f) {
      final id = f['id'] ?? f['userId'] ?? 0;
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

  Future<void> _fetchFriends() async {
    try {
      final response = await _apiClient.get('/friends/list');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _friends = list.map((e) => e as Map<String, dynamic>).toList();
          });
          _fetchOnlineStatus();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPendingRequests() async {
    try {
      final response = await _apiClient.get('/friends/requests/pending');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _pendingRequests = list.map((e) => e as Map<String, dynamic>).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    try {
      final path = accept ? '/friends/requests/$requestId/approve' : '/friends/requests/$requestId/reject';
      await _apiClient.post(path);
      await _loadData();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? '操作失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('好友列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/friend_search'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pendingRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '好友申请 (${_pendingRequests.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ..._pendingRequests.map((req) => _buildRequestCard(context, req)),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  if (_friends.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text('暂无好友', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._friends.map((friend) => _buildFriendCard(context, friend)),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> req) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = req['username'] ?? req['name'] ?? '未知';
    final avatarUrl = req['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      ApiClient.processImageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            username.toString()[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        username.toString()[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('请求添加好友', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleRequest(req['id']?.toString() ?? '', true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: const Text('同意', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => _handleRequest(req['id']?.toString() ?? '', false),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('拒绝'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = friend['username'] ?? friend['name'] ?? '未知';
    final email = friend['email'] ?? '';
    final userId = friend['id'] is int ? friend['id'] as int : int.tryParse(friend['id']?.toString() ?? '');
    final isOnline = userId != null ? (_onlineMap[userId] ?? false) : false;
    final avatarUrl = friend['avatar'] as String?;
    final displayAvatar = ApiClient.processImageUrl(avatarUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final uid = friend['id'] is int ? friend['id'] as int : int.tryParse(friend['id']?.toString() ?? '');
              if (uid != null && uid > 0) {
                UserCard.show(context,
                  userId: uid,
                  username: name.toString(),
                  avatarUrl: avatarUrl,
                  email: email.toString(),
                );
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: displayAvatar.isNotEmpty
                    ? Image.network(
                        displayAvatar,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              name.toString()[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          name.toString()[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name.toString(), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF4CAF50) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? '在线' : '离线',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(email.toString(), style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: colorScheme.primary, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/chat_detail', arguments: {
              'friendId': userId ?? 0,
              'friendName': name.toString(),
            }),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

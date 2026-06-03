import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../widgets/user_card.dart';

class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;
  int _userId = 0;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _userId = args['userId'] ?? 0;
        _username = args['username']?.toString() ?? '';
        final tab = args['tab']?.toString() ?? 'followers';
        _tabController.index = tab == 'following' ? 1 : 0;
      }
      _fetchFollowers();
      _fetchFollowing();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    if (_userId == 0) return;
    setState(() => _isLoadingFollowers = true);
    try {
      final response = await _apiClient.get('/follow/$_userId/followers', queryParameters: {'page': 1, 'size': 50});
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _followers = list.map((e) => e as Map<String, dynamic>).toList();
            _isLoadingFollowers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFollowers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _fetchFollowing() async {
    if (_userId == 0) return;
    setState(() => _isLoadingFollowing = true);
    try {
      final response = await _apiClient.get('/follow/$_userId/following', queryParameters: {'page': 1, 'size': 50});
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _following = list.map((e) => e as Map<String, dynamic>).toList();
            _isLoadingFollowing = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFollowing = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  Widget _buildUserItem(Map<String, dynamic> user, {required bool isFollower}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userId = isFollower
        ? (user['followerId'] is int ? user['followerId'] as int : int.tryParse(user['followerId']?.toString() ?? '') ?? 0)
        : (user['followingId'] is int ? user['followingId'] as int : int.tryParse(user['followingId']?.toString() ?? '') ?? 0);
    final username = isFollower
        ? (user['followerUsername']?.toString() ?? user['username']?.toString() ?? '匿名')
        : (user['username']?.toString() ?? '匿名');
    final avatar = isFollower
        ? (user['followerAvatar']?.toString() ?? user['avatar']?.toString())
        : (user['avatar']?.toString());
    final processedAvatar = ApiClient.processImageUrl(avatar);

    return ListTile(
      leading: GestureDetector(
        onTap: () {
          if (userId > 0) {
            UserCard.show(context, userId: userId, username: username, avatarUrl: avatar);
          }
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: processedAvatar.isNotEmpty
                ? Image.network(processedAvatar, fit: BoxFit.cover, width: 44, height: 44,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ))
                : Center(
                    child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ),
      ),
      title: Text(username, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      onTap: () {
        if (userId > 0) {
          UserCard.show(context, userId: userId, username: username, avatarUrl: avatar);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_username.isNotEmpty ? '$_username 的关注' : '关注'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '粉丝 (${_followers.length})'),
            Tab(text: '关注 (${_following.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Followers tab
          _isLoadingFollowers
              ? const Center(child: CircularProgressIndicator())
              : _followers.isEmpty
                  ? Center(child: Text('暂无粉丝', style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: _followers.length,
                      itemBuilder: (_, i) => _buildUserItem(_followers[i], isFollower: true),
                    ),
          // Following tab
          _isLoadingFollowing
              ? const Center(child: CircularProgressIndicator())
              : _following.isEmpty
                  ? Center(child: Text('暂无关注', style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: _following.length,
                      itemBuilder: (_, i) => _buildUserItem(_following[i], isFollower: false),
                    ),
        ],
      ),
    );
  }
}

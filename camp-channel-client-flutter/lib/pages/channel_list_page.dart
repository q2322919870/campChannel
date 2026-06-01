import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../canvas/mood_shader.dart';

/// Channel list page - ported from PC's ChannelSearchPage.vue + ChannelPage.vue.
/// Shows joined channels with tabs, allows searching & joining new channels.
class ChannelListPage extends StatefulWidget {
  const ChannelListPage({super.key});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage>
    with SingleTickerProviderStateMixin {
  final _apiClient = ApiClient();
  late TabController _tabController;

  // My channels
  List<Map<String, dynamic>> _myChannels = [];
  bool _isLoadingMyChannels = true;

  // Search
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // Selected channel posts
  Map<String, dynamic>? _selectedChannel;
  List<Map<String, dynamic>> _channelPosts = [];
  bool _isLoadingPosts = false;
  List<Map<String, dynamic>> _channelMembers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Auto-load all channels when switching to search tab
      if (_tabController.index == 1 && !_hasSearched) {
        _searchChannels();
      }
    });
    _fetchMyChannels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyChannels() async {
    try {
      final response = await _apiClient.get('/channels/my');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _myChannels = list
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
              ..sort((a, b) {
                final aCode = a['channelCode']?.toString() ?? '';
                final bCode = b['channelCode']?.toString() ?? '';
                if (aCode == 'CH-PUBLIC-001') return -1;
                if (bCode == 'CH-PUBLIC-001') return 1;
                return (a['id'] ?? 0).compareTo(b['id'] ?? 0);
              });
            _isLoadingMyChannels = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingMyChannels = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMyChannels = false);
    }
  }

  Future<void> _searchChannels() async {
    final keyword = _searchController.text.trim();
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      // Only pass keyword if non-empty, so server returns all channels when empty
      final queryParams = <String, dynamic>{};
      if (keyword.isNotEmpty) queryParams['keyword'] = keyword;

      final response = await _apiClient.get('/channels/search',
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        final channels = list.map((e) {
          final ch = Map<String, dynamic>.from(e as Map);
          ch['joinStatus'] = 'none';
          return ch;
        }).toList();

        // Mark joined channels using string comparison for type safety
        final myIds = _myChannels.map((c) => c['id']?.toString()).toSet();
        for (final ch in channels) {
          if (myIds.contains(ch['id']?.toString())) {
            ch['joinStatus'] = 'joined';
          }
        }

        // Filter out public channel
        channels.removeWhere(
            (ch) => ch['channelCode']?.toString() == 'CH-PUBLIC-001');

        if (mounted) {
          setState(() {
            _searchResults = channels;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _applyJoin(Map<String, dynamic> channel) async {
    try {
      final response =
          await _apiClient.post('/channels/${channel['id']}/join');
      if (response.data?['code'] == 200) {
        setState(() => channel['joinStatus'] = 'pending');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('申请已提交，等待审核'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _selectChannel(Map<String, dynamic> channel) async {
    setState(() {
      _selectedChannel = channel;
      _channelPosts = [];
      _channelMembers = [];
      _isLoadingPosts = true;
    });
    await Future.wait([_fetchChannelPosts(channel), _fetchChannelMembers(channel)]);
  }

  Future<void> _fetchChannelPosts(Map<String, dynamic> channel) async {
    try {
      final response = await _apiClient.get(
        '/posts/channel/${channel['id']}',
        queryParameters: {'page': 1, 'size': 20},
      );
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _channelPosts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoadingPosts = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPosts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _fetchChannelMembers(Map<String, dynamic> channel) async {
    try {
      final response = await _apiClient.get('/channels/${channel['id']}/members');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _channelMembers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _showCreateChannelDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建频道'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '频道名称',
                  hintText: '给你的频道起个名字',
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: '频道描述（选填）',
                  hintText: '介绍一下这个频道...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入频道名称')),
                );
                return;
              }

              Navigator.pop(context);
              await _createChannel(nameController.text.trim(), descController.text.trim());
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<void> _createChannel(String name, String description) async {
    try {
      final response = await _apiClient.post('/channels', data: {
        'name': name,
        'description': description.isEmpty ? null : description,
      });

      final result = response.data;
      if (mounted) {
        if (result != null && result['code'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('频道创建成功')),
          );
          // Refresh my channels list
          await _fetchMyChannels();
          // Switch to "My Channels" tab
          _tabController.animateTo(0);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChannel != null) {
      return _buildChannelDetail();
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('频道'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我的频道'),
            Tab(text: '发现频道'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyChannelsTab(theme),
          _buildSearchTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChannelDialog,
        tooltip: '创建频道',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyChannelsTab(ThemeData theme) {
    if (_isLoadingMyChannels) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions_outlined,
                size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text('暂未加入任何频道',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('去发现频道'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyChannels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myChannels.length,
        itemBuilder: (context, index) {
          final ch = _myChannels[index];
          return _buildChannelCard(ch, theme, isJoined: true);
        },
      ),
    );
  }

  Widget _buildSearchTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索频道名称或编号...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                  ),
                  onSubmitted: (_) => _searchChannels(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _searchChannels,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : !_hasSearched
                  ? Center(
                      child: Text('输入关键词搜索频道',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4))),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text('暂无结果',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final ch = _searchResults[index];
                            return _buildSearchResultCard(ch, theme);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(
      Map<String, dynamic> ch, ThemeData theme,
      {bool isJoined = false}) {
    final name = ch['name']?.toString() ?? '频道';
    final code = ch['channelCode']?.toString() ?? '';
    final desc = ch['description']?.toString() ?? '';
    final isPublic = code == 'CH-PUBLIC-001';

    return ShaderCard(
      mood: MoodMode.glass,
      intensity: 0.15,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: InkWell(
          onTap: () => _selectChannel(ch),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    isPublic ? '\u{1F3AF}' : name[0],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPublic ? '\u{1F3AF} 公共' : name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (code.isNotEmpty)
                      Text('编号: $code',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(
      Map<String, dynamic> ch, ThemeData theme) {
    final name = ch['name']?.toString() ?? '频道';
    final code = ch['channelCode']?.toString() ?? '--';
    final desc = ch['description']?.toString() ?? '暂无简介';
    final joinStatus = ch['joinStatus']?.toString() ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(name[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('编号: $code',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.5))),
                Text(desc,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: joinStatus == 'none' ? () => _applyJoin(ch) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: joinStatus == 'joined'
                  ? const Color(0xFF4ADE80)
                  : joinStatus == 'pending'
                      ? const Color(0xFFF0AD4E)
                      : theme.colorScheme.primary,
              side: BorderSide(
                color: joinStatus == 'joined'
                    ? const Color(0xFF4ADE80)
                    : joinStatus == 'pending'
                        ? const Color(0xFFF0AD4E)
                        : theme.colorScheme.primary,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(joinStatus == 'joined'
                ? '已加入'
                : joinStatus == 'pending'
                    ? '待审核'
                    : '申请加入'),
          ),
        ],
      ),
    );
  }

  // --- Channel detail view ---

  Widget _buildChannelDetail() {
    final theme = Theme.of(context);
    final ch = _selectedChannel!;
    final name = ch['name']?.toString() ?? '频道';
    final code = ch['channelCode']?.toString() ?? '';
    final isPublic = code == 'CH-PUBLIC-001';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedChannel = null),
        ),
        title: Text(isPublic ? '\u{1F3AF} 公共频道' : name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => _showMembersDialog(theme),
          ),
        ],
      ),
      body: _isLoadingPosts
          ? const Center(child: CircularProgressIndicator())
          : _channelPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 8),
                      Text('该频道暂无帖子',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchChannelPosts(ch),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _channelPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostItem(_channelPosts[index], theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post, ThemeData theme) {
    final username = post['username']?.toString() ?? '用户';
    final topic = post['topic']?.toString() ?? '';
    final content = post['content']?.toString() ?? '';
    final title = topic.isNotEmpty ? topic : (content.length > 50 ? '${content.substring(0, 50)}...' : content);
    final likeCount = post['likeCount'] ?? 0;
    final commentCount = post['commentCount'] ?? 0;
    final timeStr = post['createTime']?.toString() ?? '';

    return ShaderCard(
      mood: post['id'] % 3 == 0 ? MoodMode.glitch : MoodMode.glass,
      intensity: 0.2,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/post_detail', arguments: post);
          },
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(username[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(timeStr,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (content.isNotEmpty && title != content)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(content,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text('$likeCount', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text('$commentCount', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMembersDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('频道成员 (${_channelMembers.length})'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: _channelMembers.isEmpty
              ? const Center(child: Text('暂无成员信息'))
              : ListView.builder(
                  itemCount: _channelMembers.length,
                  itemBuilder: (_, i) {
                    final m = _channelMembers[i];
                    final name = m['username']?.toString() ?? '用户';
                    final role = m['role']?.toString() ?? 'member';
                    final roleLabel = role == 'owner'
                        ? '频道主'
                        : role == 'admin'
                            ? '管理员'
                            : '成员';
                    final roleColor = role == 'owner'
                        ? const Color(0xFFF0AD4E)
                        : role == 'admin'
                            ? const Color(0xFF4ADE80)
                            : theme.colorScheme.onSurface.withOpacity(0.5);

                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      title: Text(name, style: theme.textTheme.bodyMedium),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(roleLabel,
                            style: TextStyle(color: roleColor, fontSize: 11)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

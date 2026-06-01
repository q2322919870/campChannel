import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _apiClient = ApiClient();
  final List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  List<String> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPosts() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _results.clear();
    });

    // Save to recent searches
    setState(() {
      _recentSearches.remove(keyword);
      _recentSearches.insert(0, keyword);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });

    try {
      final response = await _apiClient.get(
        '/posts/search',
        queryParameters: {'keyword': keyword, 'page': 1, 'size': 20},
      );
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _results.clear();
            _results.addAll(list.map((e) => e as Map<String, dynamic>).toList());
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

  void _clearRecentSearch(String keyword) {
    setState(() {
      _recentSearches.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索帖子...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
          onSubmitted: (_) => _searchPosts(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchPosts,
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? _buildRecentSearches(colorScheme)
              : _results.isEmpty
                  ? _buildEmptyResult()
                  : _buildSearchResults(colorScheme),
    );
  }

  Widget _buildRecentSearches(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Text(
            '最近搜索',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._recentSearches.map((keyword) => ListTile(
                leading: Icon(Icons.history, color: colorScheme.onSurface.withOpacity(0.5)),
                title: Text(keyword),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 18),
                  onPressed: () => _clearRecentSearch(keyword),
                ),
                onTap: () {
                  _searchController.text = keyword;
                  _searchPosts();
                },
              )),
        ] else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  '搜索帖子内容、话题',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyResult() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            '没有找到相关帖子',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final post = _results[index];
        return PostCard(
          username: post['username'] ?? '未知用户',
          avatarUrl: post['avatar'] ?? '',
          title: post['topic'] ?? '帖子',
          content: post['content'] ?? '',
          images: post['images'] != null ? (post['images'] as List).cast<String>() : null,
          likeCount: post['likeCount'] ?? 0,
          commentCount: post['commentCount'] ?? 0,
          isLiked: post['isLiked'] == true,
          isPinned: post['isPinned'] == 1,
          timestamp: post['createTime'] != null
              ? DateTime.tryParse(post['createTime'].toString())
              : null,
          onLike: () {},
          onComment: () {
            Navigator.pushNamed(
              context,
              '/post_detail',
              arguments: post,
            );
          },
          onTap: () {
            Navigator.pushNamed(
              context,
              '/post_detail',
              arguments: post,
            );
          },
        );
      },
    );
  }
}

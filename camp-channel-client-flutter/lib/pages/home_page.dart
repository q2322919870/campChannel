import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../core/services/user_provider.dart';
import '../core/services/websocket_service.dart';
import '../canvas/canvas_effects.dart';
import '../core/services/burst_service.dart';
import '../widgets/blind_box.dart';
import 'channel_feed_page.dart';
import 'channel_list_page.dart';
import 'chat_list_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _apiClient = ApiClient();
  late final PageController _pageController;
  final ParticleBurstController _burstController = ParticleBurstController();
  final GlobalKey<ParticleBurstOverlayState> _burstOverlayKey = GlobalKey<ParticleBurstOverlayState>();
  List<Map<String, dynamic>> _announcements = [];
  TimePeriod _timePeriod = TimePeriod.afternoon;

  final List<Widget> _pages = [
    const ChannelFeedPage(),
    const ChannelListPage(),
    const ChatListPage(),
    const NotificationPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchUnreadCount();
    _initWebSocket();
    _syncProfile();
    _fetchAnnouncements();
    _timePeriod = getCurrentTimePeriod();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _burstController.clear();
    super.dispose();
  }

  void _initWebSocket() {
    final ws = WebSocketService();
    if (!ws.isConnected) {
      ws.connect();
    }
  }

  Future<void> _syncProfile() async {
    try {
      final response = await _apiClient.get('/users/profile');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final serverAvatar = data['avatar'] as String?;
        if (serverAvatar != null && serverAvatar.isNotEmpty) {
          await StorageService.saveAvatarUrl(serverAvatar);
        }
        if (mounted) {
          context.read<UserProvider>().updateAvatar(serverAvatar ?? '');
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread/count');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final count = result['data'] is int
            ? result['data'] as int
            : int.tryParse(result['data'].toString()) ?? 0;
        if (mounted) {
          context.read<UserProvider>().setUnreadCount(count);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response = await _apiClient.get('/announcements');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final list = result['data'] as List;
        if (mounted) {
          setState(() {
            _announcements = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _showAnnouncementDialog(Map<String, dynamic> announcement) {
    final title = announcement['title']?.toString() ?? '公告';
    final content = announcement['content']?.toString() ?? '';
    final type = announcement['type']?.toString() ?? 'scratch';
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: screenWidth - 48,
          child: type == 'blindbox'
              ? AnnouncementBlindBox(title: title, content: content)
              : ScratchCard(
                  width: screenWidth - 48,
                  height: 200,
                  coverColor: colorScheme.primary.withOpacity(0.6),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign, color: colorScheme.primary, size: 28),
                        const SizedBox(height: 10),
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(content, textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BurstService(
      controller: _burstController,
      overlayKey: _burstOverlayKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Layer 0: Fluid animated background (ported from PC WebGL)
            FluidBackground(
              primary: colorScheme.primary,
              accent: colorScheme.secondary,
              glowColor: colorScheme.primary,
            ),
            // Layer 1: Particle system with connecting lines (ported from PC CanvasEngine)
            IgnorePointer(
              child: ParticleSystemWidget(
                glowColor: colorScheme.primary,
                particleCount: 40,
              ),
            ),
            // Layer 1.5: Environment-responsive weather effects
            Positioned.fill(
              child: WeatherEffectsOverlay(period: _timePeriod),
            ),
            // Layer 2: Main content
            PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              children: _pages,
            ),
            // Particle burst overlay (triggered on like actions)
            Positioned.fill(
              child: ParticleBurstOverlay(
                key: _burstOverlayKey,
                controller: _burstController,
              ),
            ),
            // Floating announcement button
            if (_announcements.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 140,
                child: GestureDetector(
                  onTap: () => _showAnnouncementDialog(_announcements.first),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.secondary, colorScheme.primary],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final unreadCount = userProvider.unreadCount;
            return NavigationBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) {
                setState(() => _currentIndex = i);
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: '首页',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.subscriptions_outlined),
                  selectedIcon: Icon(Icons.subscriptions),
                  label: '频道',
                ),
                NavigationDestination(
                  icon: unreadCount > 0
                      ? Badge(
                          label: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(fontSize: 10),
                          ),
                          child: const Icon(Icons.chat_bubble_outline),
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  selectedIcon: unreadCount > 0
                      ? Badge(
                          label: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(fontSize: 10),
                          ),
                          child: const Icon(Icons.chat_bubble),
                        )
                      : const Icon(Icons.chat_bubble),
                  label: '消息',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: '通知',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '我的',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

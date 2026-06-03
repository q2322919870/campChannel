import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'core/services/user_provider.dart';
import 'core/network/auth_interceptor.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/channel_search_page.dart';
import 'pages/create_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/chat_detail_page.dart';
import 'pages/friend_list_page.dart';
import 'pages/friend_search_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_page.dart';
import 'pages/device_management_page.dart';
import 'pages/tree_hole_page.dart';
import 'pages/gallery_upload_page.dart';
import 'pages/favourite_page.dart';
import 'pages/group_chat_page.dart';
import 'pages/search_page.dart';
import 'pages/hot_posts_page.dart';
import 'pages/draft_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const CampChannelApp());
}

class CampChannelApp extends StatefulWidget {
  const CampChannelApp({super.key});

  @override
  State<CampChannelApp> createState() => _CampChannelAppState();
}

class _CampChannelAppState extends State<CampChannelApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    AuthInterceptor.onForceLogout = (reason) {
      _showForceLogoutDialog(reason);
    };
  }

  void _showForceLogoutDialog(String reason) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              const Text('账号下线通知'),
            ],
          ),
          content: Text(reason, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: Text(
                '重新登录',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..refreshFromStorage()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Camp Channel',
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashPage(),
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/home': (context) => const HomePage(),
              '/channel_search': (context) => const ChannelSearchPage(),
              '/create_post': (context) => const CreatePostPage(),
              '/post_detail': (context) => const PostDetailPage(),
              '/chat_detail': (context) => const ChatDetailPage(),
              '/friend_list': (context) => const FriendListPage(),
              '/friend_search': (context) => const FriendSearchPage(),
              '/settings': (context) => const SettingsPage(),
              '/admin': (context) => const AdminPage(),
              '/device_management': (context) => const DeviceManagementPage(),
              '/tree_hole': (context) => const TreeHolePage(),
              '/gallery_upload': (context) => const GalleryUploadPage(),
              '/favourites': (context) => const FavouritePage(),
              '/group_chat': (context) => const GroupChatPage(),
              '/search': (context) => const SearchPage(),
              '/hot_posts': (context) => const HotPostsPage(),
              '/drafts': (context) => const DraftListPage(),
            },
          );
        },
      ),
    );
  }
}

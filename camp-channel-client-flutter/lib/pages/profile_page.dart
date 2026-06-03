import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../core/network/api_client.dart';
import '../core/services/storage_service.dart';
import '../core/services/user_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/badge_showcase.dart';
import '../canvas/weather_effects.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _apiClient = ApiClient();
  int _postCount = 0;
  int _friendCount = 0;
  bool _isLoading = true;
  TimePeriod _timePeriod = TimePeriod.afternoon;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _timePeriod = getCurrentTimePeriod();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await _apiClient.get('/users/profile');
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        // 同步服务器最新头像到本地（支持 PC 端更换头像后在 Flutter 端即时生效）
        final serverAvatar = data['avatar'] as String?;
        print('[Avatar] 📥 Fetched profile - server avatar: $serverAvatar');
        if (serverAvatar != null && serverAvatar.isNotEmpty) {
          await StorageService.saveAvatarUrl(serverAvatar);
          if (mounted) {
            context.read<UserProvider>().updateAvatar(serverAvatar);
            print('[Avatar] 🔄 Updated UserProvider from profile fetch: $serverAvatar');
          }
        }
        if (mounted) {
          setState(() {
            _postCount = data['postCount'] ?? data['posts'] ?? 0;
            _friendCount = data['friendCount'] ?? data['fans'] ?? 0;
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

  void _handleLogout() async {
    await StorageService.clearAuth();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    // 先请求权限
    try {
      var status = await Permission.photos.status;
      print('[Avatar] 🔑 Photos permission status: $status');
      
      if (!status.isGranted) {
        status = await Permission.photos.request();
        print('[Avatar] 🔑 Photos permission after request: $status');
      }
      
      if (!status.isGranted) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        if (!storageStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('需要存储权限才能选择头像')),
            );
          }
          return;
        }
      }
    } catch (e) {
      print('[Avatar] ⚠️ Permission request error: $e');
    }

    XFile? image;
    
    // 直接使用 file_picker（更稳定可靠）
    try {
      print('[Avatar] 📸 Using file_picker to select image...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
          image = XFile(path);
          print('[Avatar] ✅ Image selected: ${image.path}');
        }
      }
    } catch (e) {
      print('[Avatar] ❌ file_picker failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
      return;
    }
    
    if (image == null) {
      print('[Avatar] ⚠️ No image selected');
      return;
    }
    
    print('[Avatar] ✅ Image selected: ${image.path}');
    
    // 验证文件是否存在
    final file = File(image.path);
    if (!await file.exists()) {
      print('[Avatar] ❌ File does not exist: ${image.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择的图片文件不存在，请重试')),
        );
      }
      return;
    }
    
    print('[Avatar] 📏 Image file size: ${await file.length()} bytes');

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: 'avatar.jpg'),
      });
      final response = await _apiClient.post('/users/avatar', data: formData);
      final result = response.data;
      if (result != null && result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final newAvatarUrl = data['url'] as String?;
        print('[Avatar] 📤 Server response: $result');
        print('[Avatar] 🖼️ New avatar URL: $newAvatarUrl');
        if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
          await StorageService.saveAvatarUrl(newAvatarUrl);
          print('[Avatar] 💾 Saved to StorageService');
          if (mounted) {
            // 清除旧头像缓存
            try {
              final oldAvatarUrl = context.read<UserProvider>().avatarUrl;
              if (oldAvatarUrl.isNotEmpty) {
                final oldFullUrl = ApiClient.processImageUrl(oldAvatarUrl);
                await DefaultCacheManager().removeFile(oldFullUrl);
                print('[Avatar] 🗑️ Cleared cache for: $oldFullUrl');
              }
            } catch (e) {
              print('[Avatar] ⚠️ Cache clear error: $e');
            }
                    
            // 立即更旹UserProvider，强制UI刷新
            context.read<UserProvider>().updateAvatar(newAvatarUrl);
            print('[Avatar] 🔄 Updated UserProvider with: $newAvatarUrl');
            Navigator.pop(context); // Close loading dialog
                    
            // 强制重建整个页面以刷新头像显示
            if (mounted) {
              setState(() {});
            }
                    
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('头像更新成功')),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['message'] ?? '上传失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  void _showAvatarPreview(BuildContext context) {
    // 从UserProvider获取最新头像
    final userProvider = context.read<UserProvider>();
    final avatarUrl = userProvider.avatarUrl;
    final fullAvatarUrl = avatarUrl.isNotEmpty 
        ? ApiClient.processImageUrl(avatarUrl)
        : '';
    final username = StorageService.getUsername() ?? '?';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: fullAvatarUrl.isNotEmpty
                  ? Image.network(
                      fullAvatarUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackAvatar(username, 200),
                    )
                  : _buildFallbackAvatar(username, 200),
            ),
            const SizedBox(height: 16),
            Text(username, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _pickAndUploadAvatar();
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('更换头像'),
                ),
                if (avatarUrl != null && avatarUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('保存'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String username, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = StorageService.getUsername() ?? '未登录';
    final email = StorageService.getEmail() ?? '';
    
    // 直接使用UserProvider的头像URL
    final userProvider = context.watch<UserProvider>();
    final avatarUrl = userProvider.avatarUrl;
    
    // 处理头像URL（不添加时间戳，由服务器控制缓存）
    final fullAvatarUrl = avatarUrl.isNotEmpty 
        ? ApiClient.processImageUrl(avatarUrl)
        : '';
    
    final isAdmin = StorageService.isAdmin();
    
    print('[Avatar] 🎨 Build - UserProvider avatar: $avatarUrl');
    print('[Avatar] 🎨 Build - Full URL: $fullAvatarUrl');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAvatarPreview(context),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: fullAvatarUrl.isNotEmpty
                                ? Image.network(
                                    fullAvatarUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('[Avatar] ❌ Image.network ERROR: $error');
                                      print('[Avatar] ❌ Failed URL: $fullAvatarUrl');
                                      print('[Avatar] ❌ Stack trace: $stackTrace');
                                      return Center(
                                        child: Text(
                                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 4),
                          child: Text(
                            email,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow(context),
                  const SizedBox(height: 12),
                  const BadgeShowcase(),
                  const SizedBox(height: 12),
                  _buildMenuItem(context, Icons.bookmark_outline, '我的收藏', () => Navigator.pushNamed(context, '/favourites')),
                  _buildMenuItem(context, Icons.drafts_outlined, '我的草稿', () => Navigator.pushNamed(context, '/drafts')),
                  _buildMenuItem(context, Icons.person_outline, '好友列表', () => Navigator.pushNamed(context, '/friend_list')),
                  _buildMenuItem(context, Icons.devices, '设备管理', () => Navigator.pushNamed(context, '/device_management')),
                  const Divider(height: 1),
                  _buildMenuItem(context, Icons.settings_outlined, '设置', () => Navigator.pushNamed(context, '/settings')),
                  if (isAdmin)
                    _buildMenuItem(context, Icons.admin_panel_settings_outlined, '管理员后台', () => Navigator.pushNamed(context, '/admin')),
                  _buildMenuItem(context, Icons.palette_outlined, '主题切换', () => _showThemeSheet(context)),
                  const SizedBox(height: 20),
                  _buildMenuItem(context, Icons.logout, '退出登录', _handleLogout, isDestructive: true),
                ],
              ),
            ),
          ),
        ],
      ),
                // Weather effects overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: WeatherEffectsOverlay(period: _timePeriod),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, '帖子', _postCount.toString()),
          _buildStatItem(context, '好友', _friendCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary),
        title: Text(label, style: TextStyle(color: color)),
        trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return const ThemeSwitcherWidget();
            },
          ),
        ),
      ),
    );
  }
}

class ThemeSwitcherWidget extends StatelessWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.palette_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text('选择主题配色', style: theme.textTheme.titleLarge),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isDark ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.light_mode, size: 18, color: !isDark ? Colors.white : colorScheme.onSurface),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.dark_mode, size: 18, color: isDark ? Colors.white : colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: themeProvider.md3Themes.length,
            itemBuilder: (context, index) {
              final config = themeProvider.md3Themes[index];
              final isSelected = themeProvider.themeIndex == index;
              return GestureDetector(
                onTap: () => themeProvider.setTheme(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? config.seedColor : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: config.seedColor.withOpacity(isSelected ? 0.4 : 0.0),
                        blurRadius: isSelected ? 12 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isSelected ? 13.5 : 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [config.seedColor, config.seedColor.withOpacity(0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: Icon(Icons.check, color: config.seedColor, size: 18),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          width: double.infinity,
                          color: theme.cardColor,
                          child: Text(
                            config.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

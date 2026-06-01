import 'package:shared_preferences/shared_preferences.dart';

/// 本地持久化存储服务
class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyRole = 'role';
  static const String _keyAvatarUrl = 'avatar_url';
  static const String _keyApiBaseUrl = 'api_base_url';

  static SharedPreferences? _prefs;

  /// 初始化 SharedPreferences 实例
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存 Token
  static Future<bool> saveToken(String token) async {
    return await _prefs?.setString(_keyToken, token) ?? false;
  }

  /// 获取 Token
  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  /// 保存用户信息
  static Future<void> saveUser({
    required int id,
    required String username,
    required String email,
    String role = 'user',
    String avatarUrl = '',
  }) async {
    await _prefs?.setInt(_keyUserId, id);
    await _prefs?.setString(_keyUsername, username);
    await _prefs?.setString(_keyEmail, email);
    await _prefs?.setString(_keyRole, role);
    await _prefs?.setString(_keyAvatarUrl, avatarUrl);
  }

  /// 获取用户 ID
  static int? getUserId() {
    return _prefs?.getInt(_keyUserId);
  }

  /// 获取用户名
  static String? getUsername() {
    return _prefs?.getString(_keyUsername);
  }

  /// 获取邮箱
  static String? getEmail() {
    return _prefs?.getString(_keyEmail);
  }

  /// 获取角色
  static String getRole() {
    return _prefs?.getString(_keyRole) ?? 'user';
  }

  /// 保存角色
  static Future<bool> saveRole(String role) async {
    return await _prefs?.setString(_keyRole, role) ?? false;
  }

  /// 获取头像地址
  static String? getAvatarUrl() {
    return _prefs?.getString(_keyAvatarUrl);
  }

  /// 保存头像地址
  static Future<bool> saveAvatarUrl(String url) async {
    return await _prefs?.setString(_keyAvatarUrl, url) ?? false;
  }

  /// 是否为管理员
  static bool isAdmin() {
    return getRole() == 'admin';
  }

  /// 保存/获取 API 基础地址
  static Future<bool> saveApiBaseUrl(String url) async {
    return await _prefs?.setString(_keyApiBaseUrl, url) ?? false;
  }

  static String? getApiBaseUrl() {
    return _prefs?.getString(_keyApiBaseUrl);
  }

  /// 清除登录状态与 Token
  static Future<void> clearAuth() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUsername);
    await _prefs?.remove(_keyEmail);
    await _prefs?.remove(_keyRole);
    await _prefs?.remove(_keyAvatarUrl);
  }

  /// 主题偏好
  static const String _keyTheme = 'theme_index';
  static const String _keyThemeMode = 'theme_mode';

  static Future<bool> saveThemeIndex(int index) async {
    return await _prefs?.setInt(_keyTheme, index) ?? false;
  }

  static int getThemeIndex() {
    return _prefs?.getInt(_keyTheme) ?? 0;
  }

  static Future<bool> saveThemeMode(String mode) async {
    return await _prefs?.setString(_keyThemeMode, mode) ?? false;
  }

  static String? getThemeMode() {
    return _prefs?.getString(_keyThemeMode);
  }

  /// 通用读取方法
  static String? get(String key) {
    return _prefs?.getString(key);
  }

  /// 通用保存方法
  static Future<bool> set(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }
}

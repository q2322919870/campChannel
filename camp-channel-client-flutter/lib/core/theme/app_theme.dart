import 'package:flutter/material.dart';
import 'md3_theme.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  int _themeIndex = 0;
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider() {
    _themeIndex = StorageService.getThemeIndex();
    final saved = StorageService.getThemeMode();
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
  }

  int get themeIndex => _themeIndex;
  ThemeMode get themeMode => _themeMode;
  
  /// 获取当前主题数据
  ThemeData get lightTheme {
    final md3Config = md3ThemeConfigs[_themeIndex % md3ThemeConfigs.length];
    return md3Config.theme;
  }
  
  ThemeData get darkTheme {
    final md3Config = md3ThemeConfigs[_themeIndex % md3ThemeConfigs.length];
    return md3Config.theme;
  }

  /// 所有可用的 MD3 主题
  List<MD3ThemeConfig> get md3Themes => md3ThemeConfigs;

  void setTheme(int index) {
    if (index < 0 || index >= md3ThemeConfigs.length) return;
    _themeIndex = index;
    StorageService.saveThemeIndex(index);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    StorageService.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    StorageService.saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}

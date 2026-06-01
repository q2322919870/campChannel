import 'package:flutter/material.dart';
import 'theme_data.dart';
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
  ThemeConfig get currentConfig => themeConfigs[_themeIndex];
  ThemeData get lightTheme => currentConfig.lightTheme;
  ThemeData get darkTheme => currentConfig.darkTheme;

  List<ThemeConfig> get allThemes => themeConfigs;

  void setTheme(int index) {
    if (index < 0 || index >= themeConfigs.length) return;
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

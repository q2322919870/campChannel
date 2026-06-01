import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final Color primary;
  final Color accent;
  final Color lightBackground;
  final Color lightSurface;
  final Color lightCard;
  final Color lightText;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkCard;
  final Color darkText;

  const ThemeConfig({
    required this.name,
    required this.primary,
    required this.accent,
    required this.lightBackground,
    required this.lightSurface,
    required this.lightCard,
    required this.lightText,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkCard,
    required this.darkText,
  });

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: lightBackground,
      onSurface: lightText,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      primaryColor: primary,
      fontFamily: 'Inter, Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightCard,
        selectedItemColor: primary,
        unselectedItemColor: lightText.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightText.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightText.withOpacity(0.08)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: lightText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: lightText, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightText),
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText.withOpacity(0.8)),
        bodySmall: TextStyle(color: lightText.withOpacity(0.6)),
      ),
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkBackground,
      onSurface: darkText,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      primaryColor: primary,
      fontFamily: 'Inter, Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0A1219),
        selectedItemColor: primary,
        unselectedItemColor: darkText.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkText.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkText.withOpacity(0.08)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: darkBackground,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: darkText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkText, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkText),
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText.withOpacity(0.8)),
        bodySmall: TextStyle(color: darkText.withOpacity(0.6)),
      ),
    );
  }
}

final List<ThemeConfig> themeConfigs = [
  const ThemeConfig(
    name: 'PC暗色',
    primary: Color(0xFF7C9FCB),
    accent: Color(0xFFF2B5D4),
    lightBackground: Color(0xFFF5F7FA),
    lightSurface: Color(0xFFEBEFF5),
    lightCard: Color(0xFFFFFFFF),
    lightText: Color(0xFF2D3748),
    darkBackground: Color(0xFF0F1923),
    darkSurface: Color(0xFF141E2B),
    darkCard: Color(0xFF1A2744),
    darkText: Color(0xFFE8EFF7),
  ),
  const ThemeConfig(
    name: 'PC明亮',
    primary: Color(0xFF7C9FCB),
    accent: Color(0xFFF2B5D4),
    lightBackground: Color(0xFFF5F7FA),
    lightSurface: Color(0xFFEBEFF5),
    lightCard: Color(0xFFFFFFFF),
    lightText: Color(0xFF2D3748),
    darkBackground: Color(0xFF0F1923),
    darkSurface: Color(0xFF141E2B),
    darkCard: Color(0xFF1A2744),
    darkText: Color(0xFFE8EFF7),
  ),
  const ThemeConfig(
    name: '经典蓝',
    primary: Color(0xFF4A9BD9),
    accent: Color(0xFFF5C6D0),
    lightBackground: Color(0xFFF0F6FC),
    lightSurface: Color(0xFFE3EEF8),
    lightCard: Color(0xFFFFFFFF),
    lightText: Color(0xFF1A365D),
    darkBackground: Color(0xFF0B1A2E),
    darkSurface: Color(0xFF0F2640),
    darkCard: Color(0xFF14304F),
    darkText: Color(0xFFE0EDF8),
  ),
];

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  ThemeData get currentTheme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF3B82F6),
      surface: Color(0xFFF8F7FF),
      onSurface: Color(0xFF1E1B4B),
      onSurfaceVariant: Color(0xFF4B5563),
      surfaceContainerHighest: Colors.white,
      outline: Color(0xFFE5E7EB),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F7FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF7C3AED),
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF3B82F6),
      surface: Color(0xFF1E1B4B),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
      surfaceContainerHighest: Color(0xFF2D1B69),
      outline: Color(0xFF64748B),
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1B4B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2D1B69),
      foregroundColor: Colors.white,
    ),
  );
}
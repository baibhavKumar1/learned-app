import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _themeKey = 'themeMode';

  ThemeNotifier(super.value);

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_themeKey);
    if (themeStr == 'light') value = ThemeMode.light;
    if (themeStr == 'dark') value = ThemeMode.dark;
  }

  Future<void> toggleTheme(bool isDark) async {
    final newTheme = isDark ? ThemeMode.dark : ThemeMode.light;
    value = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }
}

// Global instance initialized immediately (solves Hot Reload issues)
final ThemeNotifier themeNotifier = ThemeNotifier(ThemeMode.system);

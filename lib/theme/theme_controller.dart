import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton ChangeNotifier controlling light/dark mode, persisted across
/// app restarts. Mirrors the AppLocale pattern already used for language
/// switching — wrap the app in a ListenableBuilder listening to this, and
/// every screen using Theme.of(context) updates automatically.
class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _prefsKey = "app_theme_mode";

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _mode = saved == "dark" ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _mode == ThemeMode.dark ? "dark" : "light");
  }
}

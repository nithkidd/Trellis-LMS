import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_color.dart';

const String _themeColorKey = 'app_theme_color';

class ThemeNotifier extends Notifier<AppThemeColor> {
  bool _isInitialized = false;

  @override
  AppThemeColor build() {
    if (!_isInitialized) {
      _isInitialized = true;
      _loadTheme();
    }
    return AppThemeColor.blue;
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeKey = prefs.getString(_themeColorKey);
    if (themeKey != null) {
      state = AppThemeColorExtension.fromKey(themeKey);
    }
  }

  Future<void> setTheme(AppThemeColor color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeColorKey, color.key);
  }
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, AppThemeColor>(
  () {
    return ThemeNotifier();
  },
);

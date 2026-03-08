import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum ColorMode { mpk, dynamic }

class SettingsState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ColorMode _colorMode = ColorMode.mpk;

  static const _keyTheme = 'themeMode';
  static const _keyColor = 'colorMode';

  ThemeMode get themeMode => _themeMode;
  ColorMode get colorMode => _colorMode;
  bool get useDynamicColor => _colorMode == ColorMode.dynamic;

  SettingsState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_keyTheme) ?? 'system';
    final color = prefs.getString(_keyColor) ?? 'mpk';

    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _colorMode = color == 'dynamic' ? ColorMode.dynamic : ColorMode.mpk;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final val = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_keyTheme, val);
  }

  Future<void> setColorMode(ColorMode mode) async {
    _colorMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColor, mode == ColorMode.dynamic ? 'dynamic' : 'mpk');
  }

  Future<void> openGitHub() async {
    final uri = Uri.parse('https://github.com/oko3099/MPK-Rzeszow-Flutter-App');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

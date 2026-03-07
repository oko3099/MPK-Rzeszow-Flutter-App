import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum ColorMode { mpk, dynamic }

class SettingsState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ColorMode _colorMode = ColorMode.mpk;

  ThemeMode get themeMode => _themeMode;
  ColorMode get colorMode => _colorMode;
  bool get useDynamicColor => _colorMode == ColorMode.dynamic;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setColorMode(ColorMode mode) {
    _colorMode = mode;
    notifyListeners();
  }

  Future<void> openGitHub() async {
    final uri = Uri.parse('https://github.com/oko3099/MPK-Rzeszow-Flutter-App');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

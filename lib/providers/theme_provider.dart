// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'zh';

  ThemeProvider(this._storage);

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isEnglish => _language == 'en';

  int get themeIndex {
    switch (_themeMode) {
      case ThemeMode.light:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.system:
        return 2;
    }
  }

  Future<void> loadSettings() async {
    final lang = await _storage.getLanguage();
    _language = lang;
    await _loadThemeMode();
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (_themeMode) {
      case ThemeMode.light:
        await prefs.setString('theme_mode', 'light');
      case ThemeMode.dark:
        await prefs.setString('theme_mode', 'dark');
      case ThemeMode.system:
        await prefs.setString('theme_mode', 'system');
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _storage.setLanguage(lang);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _language = _language == 'zh' ? 'en' : 'zh';
    await _storage.setLanguage(_language);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeIndex(int index) {
    switch (index) {
      case 0:
        _themeMode = ThemeMode.light;
      case 1:
        _themeMode = ThemeMode.dark;
      case 2:
        _themeMode = ThemeMode.system;
    }
    _saveThemeMode();
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  String t(Map<String, String> texts) {
    return texts[_language] ?? texts['zh'] ?? '';
  }
}

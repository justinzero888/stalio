// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'zh'; // Default Chinese

  ThemeProvider(this._storage);

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isEnglish => _language == 'en';

  Future<void> loadSettings() async {
    final lang = await _storage.getLanguage();
    _language = lang;
      notifyListeners();
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
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  String t(Map<String, String> texts) {
    return texts[_language] ?? texts['zh'] ?? '';
  }
}
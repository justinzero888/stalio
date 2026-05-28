import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

/// Provider for app settings (theme, language)
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  /// Load settings from storage
  Future<void> loadSettings() async {
    // Load theme mode
    final themeStr = await _storage.getTheme();
    _themeMode = _themeModeFromString(themeStr);

    // Load language
    final lang = await _storage.getLanguage();
    _locale = Locale(lang);

    notifyListeners();
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.setTheme(_themeModeToString(mode));
    notifyListeners();
  }

  /// Set language
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _storage.setLanguage(locale.languageCode);
    notifyListeners();
  }

  /// Toggle language
  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'en') {
      await setLocale(const Locale('zh'));
    } else {
      await setLocale(const Locale('en'));
    }
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
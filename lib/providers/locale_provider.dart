import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/constants.dart';

/// Locale provider for managing language
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  /// Load locale preference from storage, falling back to system locale
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(AppConstants.keyLanguage);

    if (langCode != null) {
      _locale = Locale(langCode);
    } else {
      _locale = _detectSystemLocale();
      await prefs.setString(AppConstants.keyLanguage, _locale.languageCode);
    }
    notifyListeners();
  }

  Locale _detectSystemLocale() {
    final systemLocale = PlatformDispatcher.instance.locale;
    final code = systemLocale.languageCode;
    if (code == 'zh') return const Locale('zh');
    return const Locale('en');
  }
  
  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, locale.languageCode);
  }
  
  /// Toggle between Chinese and English
  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'zh') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('zh'));
    }
  }
  
  /// Check if current locale is Chinese
  bool get isChinese => _locale.languageCode == 'zh';
  
  /// Get display name for locale
  String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}

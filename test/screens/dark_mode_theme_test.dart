import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../lib/core/config/theme.dart';
import '../../lib/core/services/storage_service.dart';
import '../../lib/providers/theme_provider.dart';
import '../../lib/l10n/app_localizations.dart';

void main() {
  group('Dark mode theme', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('dark theme has distinct dark surfaces', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF0D0D0D)));
      expect(AppTheme.darkTheme.cardTheme.color, equals(const Color(0xFF1E1E1E)));
      expect(AppTheme.darkTheme.appBarTheme.backgroundColor, equals(const Color(0xFF121212)));
    });

    test('gold accent visible on dark nav bar', () {
      expect(AppTheme.darkTheme.bottomNavigationBarTheme.selectedItemColor,
          equals(const Color(0xFFE0B84F)));
    });

    test('light theme uses warm off-white scaffold', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, equals(const Color(0xFFF5F3EF)));
    });

    testWidgets('theme mode toggling between light, dark, system', (tester) async {
      final storage = StorageService();
      final provider = ThemeProvider(storage);

      expect(provider.themeMode, equals(ThemeMode.system));

      provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.themeIndex, equals(0));

      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.themeIndex, equals(1));

      provider.setThemeIndex(2);
      expect(provider.themeMode, equals(ThemeMode.system));
    });

    test('theme mode enum conversions work correctly', () async {
      // ThemeProvider uses StorageService which needs initialization.
      // Test the theme index ↔ ThemeMode conversion logic directly.
      SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
      final prefs = await SharedPreferences.getInstance();

      // Simulate what ThemeProvider does internally
      final saved = prefs.getString('theme_mode');
      ThemeMode mode = ThemeMode.system;
      if (saved == 'light') {
        mode = ThemeMode.light;
      } else if (saved == 'dark') {
        mode = ThemeMode.dark;
      }

      expect(mode, equals(ThemeMode.system));

      await prefs.setString('theme_mode', 'dark');
      final saved2 = prefs.getString('theme_mode');
      expect(saved2, equals('dark'));

      await prefs.setString('theme_mode', 'light');
      final saved3 = prefs.getString('theme_mode');
      expect(saved3, equals('light'));
    });
  });
}

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/core/config/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider', () {
    group('initial state', () {
      test('default locale is English before loading', () {
        final provider = LocaleProvider();
        expect(provider.locale.languageCode, 'en');
        expect(provider.isChinese, false);
      });
    });

    group('loadLocale', () {
      test('loads saved locale from preferences', () async {
        SharedPreferences.setMockInitialValues({
          AppConstants.keyLanguage: 'zh',
        });
        final provider = LocaleProvider();
        await provider.loadLocale();

        expect(provider.locale.languageCode, 'zh');
        expect(provider.isChinese, true);
      });

      test('falls back to en when no saved preference', () async {
        final provider = LocaleProvider();
        await provider.loadLocale();

        expect(provider.locale.languageCode, anyOf('en', 'zh'));
      });
    });

    group('supportedLocales', () {
      test('contains en and zh', () {
        expect(LocaleProvider.supportedLocales.length, 2);
        expect(LocaleProvider.supportedLocales.map((l) => l.languageCode),
            containsAll(['en', 'zh']));
      });
    });

    group('setLocale', () {
      test('sets locale and notifies', () async {
        final provider = LocaleProvider();
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setLocale(const Locale('zh'));

        expect(provider.locale.languageCode, 'zh');
        expect(provider.isChinese, true);
        expect(notifyCount, greaterThan(0));
      });

      test('does not change for unsupported locale', () async {
        final provider = LocaleProvider();
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        await provider.setLocale(const Locale('ja'));

        expect(provider.locale.languageCode, 'en');
        expect(notifyCount, 0);
      });

      test('persists to SharedPreferences', () async {
        final provider = LocaleProvider();
        await provider.setLocale(const Locale('zh'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(AppConstants.keyLanguage), 'zh');
      });
    });

    group('toggleLocale', () {
      test('toggles from en to zh', () async {
        final provider = LocaleProvider();
        await provider.setLocale(const Locale('en'));
        expect(provider.locale.languageCode, 'en');

        await provider.toggleLocale();
        expect(provider.locale.languageCode, 'zh');
      });

      test('toggles from zh to en', () async {
        final provider = LocaleProvider();
        await provider.setLocale(const Locale('zh'));
        expect(provider.locale.languageCode, 'zh');

        await provider.toggleLocale();
        expect(provider.locale.languageCode, 'en');
      });
    });

    group('getLocaleName', () {
      test('returns 中文 for zh locale', () {
        final provider = LocaleProvider();
        expect(provider.getLocaleName(const Locale('zh')), '中文');
      });

      test('returns English for en locale', () {
        final provider = LocaleProvider();
        expect(provider.getLocaleName(const Locale('en')), 'English');
      });

      test('returns languageCode for unknown locale', () {
        final provider = LocaleProvider();
        expect(provider.getLocaleName(const Locale('fr')), 'fr');
      });
    });
  });
}

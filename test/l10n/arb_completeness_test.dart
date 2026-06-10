import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB completeness', () {
    late Map<String, dynamic> enArb;
    late Map<String, dynamic> zhArb;

    setUp(() async {
      final enFile = File('lib/l10n/app_en.arb');
      final zhFile = File('lib/l10n/app_zh.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(zhFile.existsSync(), isTrue, reason: 'app_zh.arb must exist');

      enArb = json.decode(await enFile.readAsString()) as Map<String, dynamic>;
      zhArb = json.decode(await zhFile.readAsString()) as Map<String, dynamic>;
    });

    test('all ARB keys present in both en and zh', () {
      // Filter out @-metadata keys
      final enKeys = enArb.keys.where((k) => !k.startsWith('@')).toSet();
      final zhKeys = zhArb.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInZh = enKeys.difference(zhKeys);
      final missingInEn = zhKeys.difference(enKeys);

      expect(missingInZh, isEmpty,
          reason: 'Keys in English but missing in Chinese: $missingInZh');
      expect(missingInEn, isEmpty,
          reason: 'Keys in Chinese but missing in English: $missingInEn');
    });

    test('no legacy Blinking, AI, or trial keys remain', () {
      final allKeys = <String>{
        ...enArb.keys.where((k) => !k.startsWith('@')),
        ...zhArb.keys.where((k) => !k.startsWith('@')),
      };

      final forbidden = ['aiAssistant', 'trialBanner', 'trialProvider', 'trialInfo',
          'aiSecretsTagName', 'goodMorning', 'goodAfternoon', 'goodEvening',
          'howAreYou', 'video', 'audio', 'image', 'attachment'];

      for (final key in allKeys) {
        for (final forbiddenPrefix in forbidden) {
          expect(key.startsWith(forbiddenPrefix), isFalse,
              reason: 'Removed-feature key "$key" should not exist in ARB files');
        }
      }
    });

    test('appName is "Stalio" in both locales', () {
      expect(enArb['appName'], equals('Stalio'),
          reason: 'English appName must be "Stalio"');
      expect(zhArb['appName'], equals('Stalio'),
          reason: 'Chinese appName must be "Stalio"');
    });
  });
}

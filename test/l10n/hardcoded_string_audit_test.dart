import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hardcoded string audit', () {
    // Files that have been FULLY localized — main screen bodies with zero inline isZh ternaries
    const fullyLocalizedFiles = [
      'lib/screens/home/home_screen.dart',
      'lib/widgets/calendar_widget.dart',
      'lib/widgets/emoji_jar.dart',
      'lib/widgets/routine_item.dart',
    ];

    // Files with remaining isZh in dialogs/tag sections — Phase 4 will clean
    const phase4Files = [
      'lib/screens/settings/settings_screen.dart',
      'lib/screens/routine/routine_screen.dart',
      'lib/screens/add_entry_screen.dart',
      'lib/screens/moment/moment_screen.dart',
    ];

    final _inlineTernary = RegExp(
      r"isZh\s*\?\s*'[^']*(?:[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef]|[A-Z][a-z].*?[a-z]{3,})[^']*'",
    );

    bool _isExcluded(String trimmed) {
      if (trimmed.contains('DateFormat')) return true;
      return false;
    }

    for (final filePath in fullyLocalizedFiles) {
      test('$filePath has zero inline isZh string ternaries', () {
        final file = File(filePath);
        if (!file.existsSync()) return;
        final lines = file.readAsLinesSync();
        final violations = <String>[];

        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trim();
          if (_isExcluded(trimmed)) continue;
          if (_inlineTernary.hasMatch(trimmed)) {
            violations.add('  Line ${i + 1}: $trimmed');
          }
        }

        if (violations.isNotEmpty) {
          fail('Found inline isZh string ternaries in $filePath:\n'
              '${violations.join('\n')}\n'
              'Replace with AppLocalizations.of(context)!.someKey');
        }
      });
    }

    test('no "Blinking" remains in l10n appName', () {
      final enFile = File('lib/l10n/app_localizations_en.dart');
      final zhFile = File('lib/l10n/app_localizations_zh.dart');
      final enContent = enFile.readAsStringSync();
      final zhContent = zhFile.readAsStringSync();

      final enAppNameLine = enContent.split('\n').firstWhere(
          (l) => l.contains('appName'), orElse: () => '');
      final zhAppNameLine = zhContent.split('\n').firstWhere(
          (l) => l.contains('appName'), orElse: () => '');
      expect(enAppNameLine.contains('Blinking'), isFalse,
          reason: 'English appName should be Stalio, not Blinking');
      expect(enAppNameLine.contains('Stalio'), isTrue);
      expect(zhAppNameLine.contains('Stalio'), isTrue);
    });
  });
}

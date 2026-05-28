import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/widgets/emoji_jar.dart';

/// EmojiJarWidget._maxVisible (private) — keep in sync if widget changes.
const int _maxVisible = 30;

/// Wraps [child] with just LocaleProvider (defaults to 'en').
///
/// These tests all pass [emotionsOverride], which causes EmojiJarWidget to
/// short-circuit via `??` and never call `context.watch<JarProvider>()`,
/// so JarProvider does not need to be in the tree.
Widget _wrap(Widget child) {
  return ChangeNotifierProvider<LocaleProvider>(
    create: (_) => LocaleProvider(),
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

/// Wraps [child] with a LocaleProvider pre-seeded to Chinese.
Widget _wrapZh(Widget child, LocaleProvider provider) {
  return ChangeNotifierProvider<LocaleProvider>.value(
    value: provider,
    child: MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  group('EmojiJarWidget — overflow badge', () {
    // Regression: v1.1.0 beta UAT — Shelf tab mini jar used a plain Wrap with
    // .take(20) which overflowed its Container when emotion count > 12.
    // Fix: replaced with EmojiJarWidget(emotionsOverride: ..., canUseAI: false, isToday: false)
    // which uses _JarClipper + _EmojiGrid + the overflow badge at > 30 items.

    testWidgets('shows +N badge when emotionsOverride exceeds 30', (tester) async {
      final emotions = List.generate(_maxVisible + 5, (_) => '😊'); // 35 items

      await tester.pumpWidget(_wrap(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: emotions,
        canUseAI: false, isToday: false,
      )));
      await tester.pump();

      expect(find.text('+5'), findsOneWidget,
          reason: 'overflow badge must appear when emotions exceed $_maxVisible');
    });

    testWidgets('no badge when emotionsOverride equals 30', (tester) async {
      final emotions = List.generate(_maxVisible, (_) => '😌');

      await tester.pumpWidget(_wrap(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: emotions,
        canUseAI: false, isToday: false,
      )));
      await tester.pump();

      final badgeFinder = find.textContaining(RegExp(r'^\+\d+$'));
      expect(badgeFinder, findsNothing,
          reason: 'no overflow badge when count == $_maxVisible');
    });

    testWidgets('no badge when emotionsOverride has few items', (tester) async {
      final emotions = ['😊', '😌', '😐'];

      await tester.pumpWidget(_wrap(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: emotions,
        canUseAI: false, isToday: false,
      )));
      await tester.pump();

      final badgeFinder = find.textContaining(RegExp(r'^\+\d+$'));
      expect(badgeFinder, findsNothing);
    });

    testWidgets('empty list shows empty label (zh locale)', (tester) async {
      SharedPreferences.setMockInitialValues({'language': 'zh'});
      final provider = LocaleProvider();
      await provider.loadLocale();

      await tester.pumpWidget(_wrapZh(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: const [],
        canUseAI: false, isToday: false,
      ), provider));
      await tester.pump();

      expect(find.text('空'), findsOneWidget);
    });
  });

  group('EmojiJarWidget — AI button flag', () {
    testWidgets('AI button hidden when canUseAI: false', (tester) async {
      await tester.pumpWidget(_wrap(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: const ['😊'],
        canUseAI: false,
        isToday: false,
      )));
      await tester.pump();

      expect(find.text('问问 AI'), findsNothing);
      expect(find.text('Ask AI'), findsNothing);
    });

    testWidgets('AI button visible when canUseAI + isToday + emoji', (tester) async {
      await tester.pumpWidget(_wrap(EmojiJarWidget(
        date: DateTime(2026),
        size: 160,
        emotionsOverride: const ['😊'],
        canUseAI: true,
        isToday: true,
      )));
      await tester.pump();

      expect(find.text('Ask AI'), findsOneWidget);
    });
  });
}

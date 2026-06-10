import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/providers/entry_provider.dart';
import 'package:stalio/providers/routine_provider.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/entry_repository.dart';
import 'package:stalio/repositories/routine_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/screens/add_entry_screen.dart';
import 'package:stalio/l10n/app_localizations.dart';

class _FakeStorage extends StorageService {
  @override
  Future<void> init() async {}
}

final testTags = [
  Tag(id: 'tag_family', name: '家人', nameEn: 'Family', color: '#FF9500', category: 'custom', createdAt: DateTime(2026)),
  Tag(id: 'tag_learning', name: '学习', nameEn: 'Learning', color: '#AF52DE', category: 'custom', createdAt: DateTime(2026)),
  Tag(id: 'tag_daily', name: '日常', nameEn: 'Daily', color: '#007AFF', category: 'custom', createdAt: DateTime(2026)),
  Tag(id: 'tag_insight', name: '领悟', nameEn: 'Insight', color: '#5856D6', category: 'custom', createdAt: DateTime(2026)),
];

Widget _buildApp({List<Tag>? tags}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage();
  final entryProvider = EntryProvider(EntryRepository(storage));
  final routineProvider = RoutineProvider(RoutineRepository(storage));
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) {
        final p = TagProvider(TagRepository(storage));
        if (tags != null) p.loadTagsForTest(tags);
        return p;
      }),
      ChangeNotifierProvider<EntryProvider>.value(value: entryProvider),
      ChangeNotifierProvider<RoutineProvider>.value(value: routineProvider),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      home: const AddEntryScreen(),
      theme: ThemeData(useMaterial3: true),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

void main() {
  group('Tag auto-suggest', () {
    testWidgets('typing family keyword suggests tag_family', (tester) async {
      await tester.pumpWidget(_buildApp(tags: testTags));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'I spent time with my family today');
      await tester.pumpAndSettle();

      expect(find.text('Suggested'), findsOneWidget);
      expect(find.text('Family'), findsWidgets);
    });

    testWidgets('typing Chinese keyword suggests matching tag', (tester) async {
      await tester.pumpWidget(_buildApp(tags: testTags));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '今天学习了很多新知识');
      await tester.pumpAndSettle();

      expect(find.text('Suggested'), findsOneWidget);
      expect(find.text('Learning'), findsWidgets);
    });

    testWidgets('random text produces no suggestions', (tester) async {
      await tester.pumpWidget(_buildApp(tags: testTags));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'xyz foo bar nothing');
      await tester.pumpAndSettle();

      expect(find.text('Suggested'), findsNothing);
    });

    testWidgets('suggested tag sparkle icon visible', (tester) async {
      await tester.pumpWidget(_buildApp(tags: testTags));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'family');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('selecting suggested tag removes it from suggestions', (tester) async {
      await tester.pumpWidget(_buildApp(tags: testTags));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'family');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Family').first);
      await tester.pumpAndSettle();

      expect(find.text('Suggested'), findsNothing);
    });
  });
}

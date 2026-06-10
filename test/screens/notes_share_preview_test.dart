import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/tag_category.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/providers/entry_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/repositories/entry_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/screens/moment/moment_screen.dart';
import 'package:stalio/l10n/app_localizations.dart';

class _FakeStorage extends StorageService {
  @override Future<void> init() async {}
  @override Future<List<TagCategory>> getTagCategories() async => [];
  @override Future<List<Tag>> getTags() async => [];
}

Widget _buildApp({List<Entry>? entries}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage();
  final entryProvider = EntryProvider(EntryRepository(storage));
  if (entries != null) entryProvider.loadEntriesForTest(entries);
  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))),
      ChangeNotifierProvider(create: (_) => TagCategoryProvider(TagCategoryRepository(storage))),
      ChangeNotifierProvider<EntryProvider>.value(value: entryProvider),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      home: const MomentScreen(),
      theme: ThemeData(useMaterial3: true),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

void main() {
  final testEntries = [
    Entry(id: 'e1', type: EntryType.freeform, content: 'Test content', tagIds: [], createdAt: DateTime(2026, 6, 1), updatedAt: DateTime(2026, 6, 1)),
  ];

  group('Notes share — preview', () {
    testWidgets('preview renders selected entry content', (tester) async {
      await tester.pumpWidget(_buildApp(entries: testEntries));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test content'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test content'), findsWidgets);
    });

    testWidgets('Share button present in preview', (tester) async {
      await tester.pumpWidget(_buildApp(entries: testEntries));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test content'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('Save as file button present in preview', (tester) async {
      await tester.pumpWidget(_buildApp(entries: testEntries));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test content'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(find.text('Save as file'), findsOneWidget);
    });
  });
}

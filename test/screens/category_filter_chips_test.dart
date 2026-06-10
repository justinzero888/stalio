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
  @override
  Future<void> init() async {}
}

final testCategories = [
  TagCategory(id: 'cat_health', name: '健康', nameEn: 'Health', color: '#34C759', icon: '💚', createdAt: DateTime(2026)),
  TagCategory(id: 'cat_work', name: '工作', nameEn: 'Work', color: '#007AFF', icon: '💼', createdAt: DateTime(2026)),
];

final testTags = [
  Tag(id: 't1', name: '跑步', nameEn: 'Running', color: '#34C759', categoryId: 'cat_health', createdAt: DateTime(2026)),
  Tag(id: 't2', name: '会议', nameEn: 'Meeting', color: '#007AFF', categoryId: 'cat_work', createdAt: DateTime(2026)),
  Tag(id: 't3', name: '杂项', nameEn: 'Misc', color: '#9E9E9E', createdAt: DateTime(2026)),
];

Widget _buildApp({List<Tag>? tags, List<TagCategory>? categories, List<Entry>? entries}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage();
  final entryProvider = EntryProvider(EntryRepository(storage));
  if (entries != null) entryProvider.loadEntriesForTest(entries);

  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) {
        final p = TagProvider(TagRepository(storage));
        if (tags != null) p.loadTagsForTest(tags);
        return p;
      }),
      ChangeNotifierProvider(create: (_) {
        final p = TagCategoryProvider(TagCategoryRepository(storage));
        if (categories != null) p.loadCategoriesForTest(categories);
        return p;
      }),
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
  group('Category filter chips in Notes tab', () {
    testWidgets('category chips render when categories exist', (tester) async {
      await tester.pumpWidget(_buildApp(
        tags: testTags,
        categories: testCategories,
        entries: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('no category chips when no categories', (tester) async {
      await tester.pumpWidget(_buildApp(
        tags: testTags,
        entries: [],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Health'), findsNothing);
      expect(find.text('Work'), findsNothing);
    });

    testWidgets('selecting category filter chip filters entries', (tester) async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Running entry', tagIds: ['t1'],
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
        Entry(id: 'e2', type: EntryType.freeform, content: 'Meeting entry', tagIds: ['t2'],
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
        Entry(id: 'e3', type: EntryType.freeform, content: 'Misc entry', tagIds: ['t3'],
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      ];
      await tester.pumpWidget(_buildApp(
        tags: testTags,
        categories: testCategories,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Running entry'), findsOneWidget);
      expect(find.text('Meeting entry'), findsOneWidget);
      expect(find.text('Misc entry'), findsOneWidget);

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(find.text('Running entry'), findsOneWidget);
      expect(find.text('Meeting entry'), findsNothing);
      expect(find.text('Misc entry'), findsNothing);
    });

    testWidgets('All chip in category row clears filter', (tester) async {
      final entries = [
        Entry(id: 'e1', type: EntryType.freeform, content: 'Running entry', tagIds: ['t1'],
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
        Entry(id: 'e2', type: EntryType.freeform, content: 'Meeting entry', tagIds: ['t2'],
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      ];
      await tester.pumpWidget(_buildApp(
        tags: testTags,
        categories: testCategories,
        entries: entries,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();
      expect(find.text('Meeting entry'), findsNothing);

      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(find.text('Running entry'), findsOneWidget);
      expect(find.text('Meeting entry'), findsOneWidget);
    });
  });
}

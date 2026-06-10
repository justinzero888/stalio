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
import 'package:stalio/providers/routine_provider.dart';
import 'package:stalio/providers/summary_provider.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/repositories/entry_repository.dart';
import 'package:stalio/repositories/routine_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/screens/cherished/tag_analytics_tab.dart';

class _FakeStorage extends StorageService {
  @override
  Future<void> init() async {}
}

final testTags = [
  Tag(id: 't1', name: '跑步', nameEn: 'Running', color: '#34C759', categoryId: 'cat_health', createdAt: DateTime(2026)),
  Tag(id: 't2', name: '会议', nameEn: 'Meeting', color: '#007AFF', categoryId: 'cat_work', createdAt: DateTime(2026)),
];

final testCategories = [
  TagCategory(id: 'cat_health', name: '健康', nameEn: 'Health', color: '#34C759', icon: '💚', createdAt: DateTime(2026)),
  TagCategory(id: 'cat_work', name: '工作', nameEn: 'Work', color: '#007AFF', icon: '💼', createdAt: DateTime(2026)),
];

Widget _buildTestApp({List<Tag>? tags, List<TagCategory>? categories, List<Entry>? entries}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage();

  final entryProvider = EntryProvider(EntryRepository(storage));
  if (entries != null) entryProvider.loadEntriesForTest(entries);
  final routineProvider = RoutineProvider(RoutineRepository(storage));
  final summaryProvider = SummaryProvider(entryProvider, routineProvider);

  return MultiProvider(
    providers: [
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
      ChangeNotifierProvider<RoutineProvider>.value(value: routineProvider),
      ChangeNotifierProvider<SummaryProvider>.value(value: summaryProvider),
    ],
    child: MaterialApp(
      home: Builder(builder: (context) => TagAnalyticsTab(
        summary: context.watch<SummaryProvider>(),
        isZh: false,
      )),
      theme: ThemeData(useMaterial3: true),
    ),
  );
}

void main() {
  group('TagAnalyticsTab', () {
    testWidgets('shows empty state when no tags', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('No tag data yet'), findsOneWidget);
    });

    testWidgets('renders top tags section when tags exist', (tester) async {
      final entry = Entry(
        id: 'e1', type: EntryType.freeform, content: 'Test', tagIds: ['t1', 't2'],
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      await tester.pumpWidget(_buildTestApp(tags: testTags, categories: testCategories, entries: [entry]));
      await tester.pumpAndSettle();

      expect(find.text('Top Tags'), findsOneWidget);
      expect(find.text('Running'), findsWidgets);
      expect(find.text('Meeting'), findsWidgets);
    });

    testWidgets('shows co-occurrence section', (tester) async {
      final entry = Entry(
        id: 'e1', type: EntryType.freeform, content: 'Test', tagIds: ['t1', 't2'],
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      await tester.pumpWidget(_buildTestApp(tags: testTags, categories: testCategories, entries: [entry]));
      await tester.pumpAndSettle();

      expect(find.text('Co-occurrence'), findsOneWidget);
    });

    testWidgets('shows usage timeline section', (tester) async {
      final entry = Entry(
        id: 'e1', type: EntryType.freeform, content: 'Test', tagIds: ['t1'],
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );
      await tester.pumpWidget(_buildTestApp(tags: testTags, categories: testCategories, entries: [entry]));
      await tester.pumpAndSettle();

      expect(find.text('Usage Timeline'), findsOneWidget);
    });
  });
}

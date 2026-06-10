import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/providers/theme_provider.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/tag_category.dart';
import 'package:stalio/screens/settings/settings_screen.dart';
import 'package:stalio/l10n/app_localizations.dart';

class _FakeStorage extends StorageService {
  @override
  Future<void> init() async {}

  @override
  bool getVoiceEnabled() => false;

  @override
  Future<void> setVoiceEnabled(bool value) async {}
}

void main() {
  Widget _wrap(Widget child,
      {List<Tag>? tags, List<TagCategory>? categories}) {
    SharedPreferences.setMockInitialValues({});
    final storage = _FakeStorage();
    final tagRepo = TagRepository(storage);
    final catRepo = TagCategoryRepository(storage);

    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
        ChangeNotifierProvider(create: (_) {
          final p = TagProvider(tagRepo);
          if (tags != null) p.loadTagsForTest(tags);
          return p;
        }),
        ChangeNotifierProvider(create: (_) {
          final p = TagCategoryProvider(catRepo);
          if (categories != null) p.loadCategoriesForTest(categories);
          return p;
        }),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        home: child,
        theme: ThemeData(useMaterial3: true),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    );
  }

  final testCategories = [
    TagCategory(id: 'cat_health', name: '健康', nameEn: 'Health', color: '#34C759', icon: '💚', createdAt: DateTime(2026)),
    TagCategory(id: 'cat_work', name: '工作', nameEn: 'Work', color: '#007AFF', icon: '💼', createdAt: DateTime(2026)),
  ];

  final testTags = [
    Tag(id: 't1', name: '跑步', nameEn: 'Running', color: '#34C759', categoryId: 'cat_health', createdAt: DateTime(2026)),
    Tag(id: 't2', name: '会议', nameEn: 'Meeting', color: '#007AFF', categoryId: 'cat_work', createdAt: DateTime(2026)),
    Tag(id: 't3', name: '杂项', nameEn: 'Misc', color: '#9E9E9E', createdAt: DateTime(2026)),
    Tag(id: 't_private', name: '私密', nameEn: 'Private', color: '#9E9E9E', category: 'system', createdAt: DateTime(2026)),
  ];

  group('Phase 4: Tag Category UI', () {
    testWidgets('expandable category sections render with tags', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('2 tags'), findsWidgets);
    });

    testWidgets('collapsing a category hides its tags', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);

      await tester.tap(find.text('Health'));
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsNothing);
    });

    testWidgets('add category dialog opens and has fields', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect(find.text('Category name'), findsOneWidget);
      expect(find.text('English name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('edit category dialog opens with existing values', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      final editButtons = find.byIcon(Icons.edit_outlined);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
    });

    testWidgets('delete category dialog shows confirmation', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      final deleteButtons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Category'), findsOneWidget);
      expect(find.textContaining('uncategorized'), findsOneWidget);
    });

    testWidgets('long-press on tag enters selection mode', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Running'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsWidgets);
      await tester.ensureVisible(find.text('Assign Category'));
      await tester.pumpAndSettle();
      expect(find.text('Assign Category'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Recolor'), findsOneWidget);
    });

    testWidgets('merge dialog shows tag selection', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Running'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meeting'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Merge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(find.text('Merge Tags'), findsOneWidget);
    });

    testWidgets('recolor dialog shows color picker', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Running'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Recolor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recolor'));
      await tester.pumpAndSettle();

      expect(find.text('Batch Recolor'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('assign category dialog shows categories', (tester) async {
      await tester.pumpWidget(_wrap(
        const SettingsScreen(initialTab: 1),
        tags: testTags,
        categories: testCategories,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Running'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Assign Category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign Category'));
      await tester.pumpAndSettle();

      expect(find.text('Assign to Category'), findsOneWidget);
      expect(find.textContaining('Health'), findsWidgets);
    });
  });
}

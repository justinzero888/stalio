import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/core/services/export_service.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/providers/theme_provider.dart';
import 'package:stalio/providers/routine_provider.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/repositories/routine_repository.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/models/routine.dart';
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

  @override
  Future<List<Routine>> getRoutines() async => [];

  @override
  Future<void> addRoutine(Routine r) async {}

  @override
  Future<List<TagCategory>> getTagCategories() async => [];

  @override
  Future<List<Tag>> getTags() async => [];
}

void main() {
  Widget _wrap(Widget child) {
    SharedPreferences.setMockInitialValues({});
    final storage = _FakeStorage();
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<ExportService>.value(value: ExportService(storage)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
        ChangeNotifierProvider(
          create: (_) => TagProvider(TagRepository(storage))..loadTags(),
        ),
        ChangeNotifierProvider(
          create: (_) => TagCategoryProvider(TagCategoryRepository(storage)),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutineProvider(RoutineRepository(storage))..loadRoutines(),
        ),
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

  group('Phase 2: Settings Backup & Restore', () {
    testWidgets('Backup button is present with correct label', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Full Backup (ZIP)'), findsOneWidget);
    });

    testWidgets('Restore button is present with correct label', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Scroll to bottom of General tab to reveal restore button
      final listView = find.byType(ListView).first;
      await tester.drag(listView, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Restore Data'), findsOneWidget);
    });

    testWidgets('Backup & Restore section header is present', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Backup & Restore'), findsOneWidget);
    });

    testWidgets('Backup list tile has archive icon', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('Restore list tile has restore icon', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restore_outlined), findsOneWidget);
    });

    testWidgets('Backup button is tappable without crash', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Full Backup (ZIP)'));
      await tester.pump();
    });
  });
}

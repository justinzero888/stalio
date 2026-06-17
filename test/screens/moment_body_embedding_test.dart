import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/models/tag_category.dart';
import 'package:stalio/providers/entry_provider.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/providers/tag_category_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/repositories/entry_repository.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/repositories/tag_category_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/screens/moment/moment_screen.dart';
import 'package:stalio/l10n/app_localizations.dart';

class _FakeStorage extends StorageService {
  @override Future<void> init() async {}
  @override Future<List<Entry>> getEntries() async => [];
  @override Future<List<Tag>> getTags() async => [];
  @override Future<List<TagCategory>> getTagCategories() async => [];
}

Widget _wrapEmbedded(Widget body) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))),
      ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))),
      ChangeNotifierProvider(create: (_) => TagCategoryProvider(TagCategoryRepository(storage))),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: DefaultTabController(
          length: 2,
          child: Column(children: [
            const TabBar(tabs: [Tab(text: 'Habits'), Tab(text: 'Notes')]),
            Expanded(child: TabBarView(children: [
              const Text('Habits Tab'),
              body,
            ])),
          ]),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('MomentBody renders inside TabBarView without nested Scaffold conflict', (tester) async {
    await tester.pumpWidget(_wrapEmbedded(const MomentBody()));
    await tester.pumpAndSettle();

    // Switch to the Notes tab where MomentBody lives
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('MomentScreen standalone still renders Scaffold', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = _FakeStorage();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
        ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))),
        ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))),
        ChangeNotifierProvider(create: (_) => TagCategoryProvider(TagCategoryRepository(storage))),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MomentScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

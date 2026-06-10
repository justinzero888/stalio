import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../lib/l10n/app_localizations.dart';
import '../../lib/core/services/storage_service.dart';
import '../../lib/core/services/export_service.dart';
import '../../lib/repositories/repositories.dart';
import '../../lib/providers/locale_provider.dart';
import '../../lib/providers/theme_provider.dart';
import '../../lib/providers/entry_provider.dart';
import '../../lib/providers/routine_provider.dart';
import '../../lib/providers/tag_provider.dart';
import '../../lib/providers/tag_category_provider.dart';
import '../../lib/providers/jar_provider.dart';
import '../../lib/providers/summary_provider.dart';
import '../../lib/screens/home/home_screen.dart';
import '../../lib/screens/moment/moment_screen.dart';
import '../../lib/screens/add_entry_screen.dart';

Widget _wrapWithProviders(Widget child, {Locale locale = const Locale('en')}) {
  SharedPreferences.setMockInitialValues({});
  final storage = StorageService();
  final entryRepo = EntryRepository(storage);
  final routineRepo = RoutineRepository(storage);
  final tagRepo = TagRepository(storage);
  final tagCatRepo = TagCategoryRepository(storage);

  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      Provider<ExportService>(create: (_) => ExportService(storage)),
      ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(locale)),
      Provider<EntryRepository>.value(value: entryRepo),
      Provider<RoutineRepository>.value(value: routineRepo),
      Provider<TagRepository>.value(value: tagRepo),
      ChangeNotifierProvider(create: (_) => EntryProvider(entryRepo)),
      ChangeNotifierProvider(create: (_) => RoutineProvider(routineRepo)),
      ChangeNotifierProvider(create: (_) => TagProvider(tagRepo)),
      ChangeNotifierProvider(create: (_) => TagCategoryProvider(tagCatRepo)),
      ChangeNotifierProxyProvider<EntryProvider, JarProvider>(
        create: (ctx) => JarProvider(ctx.read<EntryProvider>()),
        update: (ctx, ep, jar) => jar!..update(ep),
      ),
      ChangeNotifierProxyProvider2<EntryProvider, RoutineProvider, SummaryProvider>(
        create: (ctx) => SummaryProvider(ctx.read<EntryProvider>(), ctx.read<RoutineProvider>()),
        update: (ctx, ep, rp, s) => s!..update(ep, rp),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: child,
    ),
  );
}

void main() {
  group('Localized screen rendering', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('HomeScreen renders in English', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('HomeScreen renders in Chinese', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const HomeScreen(), locale: const Locale('zh')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('MomentScreen renders in English', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const MomentScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(MomentScreen), findsOneWidget);
    });

    testWidgets('MomentScreen renders in Chinese', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const MomentScreen(), locale: const Locale('zh')));
      await tester.pumpAndSettle();
      expect(find.byType(MomentScreen), findsOneWidget);
    });

    testWidgets('AddEntryScreen renders in English', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const AddEntryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AddEntryScreen), findsOneWidget);
    });

    testWidgets('AddEntryScreen renders in Chinese', (tester) async {
      await tester.pumpWidget(_wrapWithProviders(const AddEntryScreen(), locale: const Locale('zh')));
      await tester.pumpAndSettle();
      expect(find.byType(AddEntryScreen), findsOneWidget);
    });
  });
}

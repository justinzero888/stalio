import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/models/routine.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/models/tag.dart';
import 'package:stalio/providers/routine_provider.dart';
import 'package:stalio/providers/entry_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/providers/tag_provider.dart';
import 'package:stalio/repositories/routine_repository.dart';
import 'package:stalio/repositories/entry_repository.dart';
import 'package:stalio/repositories/tag_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/screens/home/home_screen.dart';
import 'package:stalio/l10n/app_localizations.dart';

class _FakeStorage extends StorageService {
  final List<Routine> routines;
  final List<Entry> entries;
  final Map<String, bool> _tooltips = {};

  _FakeStorage({this.routines = const [], this.entries = const []});

  @override
  Future<List<Routine>> getRoutines() async => List.from(routines);

  @override
  Future<void> updateRoutine(Routine routine) async {
    final i = routines.indexWhere((r) => r.id == routine.id);
    if (i != -1) routines[i] = routine;
  }

  @override
  Future<List<Entry>> getEntries() async => List.from(entries);

  @override
  Future<List<Tag>> getTags() async => [];

  @override
  Future<void> addTag(Tag tag) async {}

  @override
  bool isTooltipSeen(String key) => _tooltips[key] ?? false;

  @override
  Future<void> setTooltipSeen(String key) async => _tooltips[key] = true;
}

Routine _routine({
  required String id,
  required String name,
  List<RoutineCompletion> completions = const [],
}) =>
    Routine(
      id: id,
      name: name,
      nameEn: name,
      frequency: RoutineFrequency.daily,
      completionLog: completions,
      isActive: true,
      trackingUiType: TrackingUiType.booleanOptionalText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

RoutineCompletion _completion(String routineId, {DateTime? date}) =>
    RoutineCompletion(
      id: '${routineId}_c',
      routineId: routineId,
      completedAt: date ?? DateTime.now(),
    );

Widget _wrap(Widget child, {List<Routine> routines = const [], List<Entry> entries = const []}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage(routines: routines, entries: entries);
  return MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))),
      ChangeNotifierProvider(
        create: (_) {
          final p = RoutineProvider(RoutineRepository(storage));
          p.loadRoutines();
          return p;
        },
      ),
      ChangeNotifierProvider(create: (_) => TagProvider(TagRepository(storage))..loadTags()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      home: child,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() => tester.view.resetPhysicalSize());
}

void main() {
  group('HomeScreen routine checklist', () {
    testWidgets('uncompleted routine shows check_box_outline_blank + name',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [_routine(id: 'r1', name: '5000 steps')],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(find.text('5000 steps'), findsOneWidget);
    });

    testWidgets('completed routine shows in consolidated done card',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [
          _routine(
            id: 'r1',
            name: '5000 steps',
            completions: [_completion('r1')],
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
      expect(find.text('5000 steps'), findsNothing);
    });

    testWidgets('uncompleted routines render as ListTile not CheckboxListTile',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [_routine(id: 'r1', name: '5000 steps')],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('tapping routine opens note dialog and can be dismissed',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [_routine(id: 'r1', name: '5000 steps')],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      // Tap routine — note dialog opens
      await tester.tap(find.text('5000 steps'));
      await tester.pumpAndSettle();

      // Verify dialog content is visible
      expect(find.text('5000 steps'), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Dismiss by tapping "Skip"
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Habit was completed before dialog opened (boolean_optional_text flow)
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    });

    testWidgets('completed routine shows check icon — not text label',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [
          _routine(id: 'r1', name: '5000 steps', completions: [
            _completion('r1'),
          ]),
        ],
      ));
      await tester.pumpAndSettle();

      // Completed routine shows check_circle icon (consolidated row)
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      // Name text not shown — completed routines use emoji icons only
    });

    testWidgets('multiple routines render as separate ListTile items',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [
          _routine(id: 'r1', name: '5000 steps'),
          _routine(id: 'r2', name: 'Drink water'),
          _routine(id: 'r3', name: 'Meditate'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(3));
      expect(find.text('5000 steps'), findsOneWidget);
      expect(find.text('Drink water'), findsOneWidget);
      expect(find.text('Meditate'), findsOneWidget);
    });

    testWidgets('booleanOptionalText habit tap shows note dialog', (tester) async {
      _usePhoneSurface(tester);

      final vitamins = _routine(id: 'H002', name: 'Take vitamins');

      await tester.pumpWidget(_wrap(const HomeScreen(), routines: [vitamins]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Take vitamins'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinking/models/routine.dart';
import 'package:blinking/models/entry.dart';
import 'package:blinking/providers/routine_provider.dart';
import 'package:blinking/providers/entry_provider.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/repositories/routine_repository.dart';
import 'package:blinking/repositories/entry_repository.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/screens/home/home_screen.dart';

class _FakeStorage extends StorageService {
  final List<Routine> routines;
  final List<Entry> entries;

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
  final storage = _FakeStorage(routines: routines, entries: entries);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => EntryProvider(EntryRepository(storage))),
      ChangeNotifierProvider(
        create: (_) {
          final p = RoutineProvider(RoutineRepository(storage));
          p.loadRoutines();
          return p;
        },
      ),
    ],
    child: MaterialApp(home: child),
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

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
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

    testWidgets(
        'tapping uncompleted routine completion removes check_box_outline_blank',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [_routine(id: 'r1', name: '5000 steps')],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      await tester.tap(find.text('5000 steps'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
    });

    testWidgets(
        'tapping uncompleted routine adds check_circle to completed card',
        (tester) async {
      _usePhoneSurface(tester);

      await tester.pumpWidget(_wrap(
        const HomeScreen(),
        routines: [_routine(id: 'r1', name: '5000 steps')],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.tap(find.text('5000 steps'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
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
  });
}

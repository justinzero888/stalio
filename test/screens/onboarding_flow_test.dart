import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stalio/models/routine.dart';
import 'package:stalio/providers/routine_provider.dart';
import 'package:stalio/providers/locale_provider.dart';
import 'package:stalio/repositories/routine_repository.dart';
import 'package:stalio/core/services/storage_service.dart';
import 'package:stalio/l10n/app_localizations.dart';
import 'package:stalio/screens/onboarding/onboarding_flow.dart';

class _FakeStorage extends StorageService {
  final List<Routine> routines;

  _FakeStorage(this.routines);

  @override
  Future<List<Routine>> getRoutines() async => List.from(routines);

  @override
  Future<void> updateRoutine(Routine routine) async {
    final i = routines.indexWhere((r) => r.id == routine.id);
    if (i != -1) routines[i] = routine;
  }
}

Widget _wrap(Widget child, {List<Routine> routines = const []}) {
  SharedPreferences.setMockInitialValues({});
  final storage = _FakeStorage(routines);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()..setLocale(const Locale('en'))),
      ChangeNotifierProvider(create: (_) {
        final p = RoutineProvider(RoutineRepository(storage));
        p.loadRoutines();
        return p;
      }),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      home: child,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

Routine _makeRoutine(String id, String nameEn, {bool isDefaultBundle = false, TrackingUiType trackingUiType = TrackingUiType.boolean}) {
  return Routine(
    id: id,
    name: nameEn,
    nameEn: nameEn,
    icon: '\u{1F4A7}',
    frequency: RoutineFrequency.daily,
    isActive: false,
    isDefaultBundle: isDefaultBundle,
    trackingUiType: trackingUiType,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Future<void> _goToScreen(WidgetTester tester, int page) async {
  if (page == 1) {
    await tester.tap(find.text('Get Started'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  } else if (page == 2) {
    await _goToScreen(tester, 1);
    final btn = find.text('Select Your Habits');
    await tester.ensureVisible(btn);
    await tester.pumpAndSettle();
    await tester.tap(btn);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('onboarding shows welcome screen with Get Started button', (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () {}),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Do. Tally. Grow.'), findsWidgets);
  });

  testWidgets('Get Started navigates to How It Works screen', (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () {}),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
      ],
    ));
    await tester.pumpAndSettle();

    await _goToScreen(tester, 1);

    expect(find.text('How It Works'), findsOneWidget);
    expect(find.text('ONE TAP'), findsOneWidget);
    expect(find.text('ONE NUMBER'), findsOneWidget);
    expect(find.text('ONE NOTE'), findsOneWidget);
  });

  testWidgets('Select Your Habits navigates to habit selection screen', (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () {}),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
        _makeRoutine('seed_H003', 'Step outside', isDefaultBundle: true),
      ],
    ));
    await tester.pumpAndSettle();

    await _goToScreen(tester, 2);

    expect(find.text('Your Habits'), findsOneWidget);
    expect(find.text('Drink water'), findsWidgets);
    expect(find.text('Step outside'), findsWidgets);
    expect(find.text('Start Tracking →'), findsOneWidget);
  });

  testWidgets('habit toggle updates selection count', (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () {}),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
      ],
    ));
    await tester.pumpAndSettle();

    await _goToScreen(tester, 2);

    // The habit should be pre-selected (default bundle)
    expect(find.byIcon(Icons.check), findsWidgets);

    // Tap the habit card to toggle it off
    final habitCard = find.text('Drink water');
    await tester.ensureVisible(habitCard);
    await tester.pumpAndSettle();
    await tester.tap(habitCard);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Check icon should disappear
    expect(find.byIcon(Icons.check), findsNothing);

    // Tap again to re-select
    await tester.tap(find.text('Drink water'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsWidgets);
  });

  testWidgets('Start Tracking triggers onComplete callback', (tester) async {
    bool completed = false;
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () => completed = true),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
      ],
    ));
    await tester.pumpAndSettle();

    await _goToScreen(tester, 2);

    await tester.tap(find.text('Start Tracking →'));
    await tester.pumpAndSettle();

    expect(completed, true);
  });

  testWidgets('Add more from library navigates to habit library without freeze', (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingFlow(onComplete: () {}),
      routines: [
        _makeRoutine('seed_H001', 'Drink water', isDefaultBundle: true),
        _makeRoutine('seed_H002', 'Take vitamins', isDefaultBundle: false),
      ],
    ));
    await tester.pumpAndSettle();

    await _goToScreen(tester, 2);

    final libraryBtn = find.textContaining('library');
    await tester.ensureVisible(libraryBtn);
    await tester.tap(libraryBtn);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Take vitamins'), findsOneWidget);
  });
}

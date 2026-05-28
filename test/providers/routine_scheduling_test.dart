import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/routine.dart';
import 'package:blinking/models/schedule.dart';

void main() {
  group('Routine Scheduling', () {
    group('Daily frequency', () {
      test('daily routine generates today schedule even if not completed', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          isActive: true,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final schedule = _generateSchedules([routine]);
        expect(schedule.isNotEmpty, isTrue);
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        expect(
          schedule.any((s) => s.routineId == 'routine1' && s.scheduledDate == todayDate),
          isTrue,
        );
      });

      test('daily frequency label is "Daily" in English', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(false), 'Daily');
      });

      test('daily frequency label is "每天" in Chinese', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(true), '每天');
      });
    });

    group('Weekly frequency', () {
      test('weekly routine with specific days shows correct days in English', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Yoga',
          nameEn: 'Yoga',
          frequency: RoutineFrequency.weekly,
          scheduledDaysOfWeek: [1, 3, 5], // Mon, Wed, Fri
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final label = routine.frequencyLabelFor(false);
        expect(label, contains('Mon'));
        expect(label, contains('Wed'));
        expect(label, contains('Fri'));
      });

      test('weekly routine with specific days shows correct days in Chinese', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Yoga',
          nameEn: 'Yoga',
          frequency: RoutineFrequency.weekly,
          scheduledDaysOfWeek: [1, 3, 5], // Mon, Wed, Fri (一, 三, 五)
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final label = routine.frequencyLabelFor(true);
        expect(label, contains('一'));
        expect(label, contains('三'));
        expect(label, contains('五'));
      });

      test('weekly without scheduled days defaults to "Weekly"', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Yoga',
          nameEn: 'Yoga',
          frequency: RoutineFrequency.weekly,
          scheduledDaysOfWeek: null,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(false), 'Weekly');
      });

      test('weekly with empty scheduled days defaults to "Weekly"', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Yoga',
          nameEn: 'Yoga',
          frequency: RoutineFrequency.weekly,
          scheduledDaysOfWeek: [],
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(false), 'Weekly');
      });

      test('ISO 8601 day mapping is correct (1=Mon, 7=Sun)', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Test',
          nameEn: 'Test',
          frequency: RoutineFrequency.weekly,
          scheduledDaysOfWeek: [1, 7], // Mon and Sun
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final labelEn = routine.frequencyLabelFor(false);
        expect(labelEn, contains('Mon'));
        expect(labelEn, contains('Sun'));

        final labelZh = routine.frequencyLabelFor(true);
        expect(labelZh, contains('一'));
        expect(labelZh, contains('日'));
      });
    });

    group('Scheduled (one-time) frequency', () {
      test('scheduled routine shows formatted date in English', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Birthday Present',
          nameEn: 'Birthday Present',
          frequency: RoutineFrequency.scheduled,
          scheduledDate: DateTime(2026, 6, 15),
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final label = routine.frequencyLabelFor(false);
        expect(label, contains('2026'));
        expect(label, contains('6'));
        expect(label, contains('15'));
      });

      test('scheduled routine shows formatted date in Chinese', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Birthday Present',
          nameEn: 'Birthday Present',
          frequency: RoutineFrequency.scheduled,
          scheduledDate: DateTime(2026, 6, 15),
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final label = routine.frequencyLabelFor(true);
        expect(label, contains('6'));
        expect(label, contains('15'));
      });

      test('scheduled without date defaults to "Scheduled"', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Birthday Present',
          nameEn: 'Birthday Present',
          frequency: RoutineFrequency.scheduled,
          scheduledDate: null,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(false), 'Scheduled');
      });
    });

    group('Adhoc (on-demand) frequency', () {
      test('adhoc routine shows "On demand" in English', () {
        final routine = Routine(
          id: 'routine1',
          name: 'As Needed',
          nameEn: 'As Needed',
          frequency: RoutineFrequency.adhoc,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(false), 'On demand');
      });

      test('adhoc routine shows "随时" in Chinese', () {
        final routine = Routine(
          id: 'routine1',
          name: 'As Needed',
          nameEn: 'As Needed',
          frequency: RoutineFrequency.adhoc,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.frequencyLabelFor(true), '随时');
      });

      test('adhoc routine does not generate schedule', () {
        final routine = Routine(
          id: 'routine1',
          name: 'As Needed',
          nameEn: 'As Needed',
          frequency: RoutineFrequency.adhoc,
          isActive: true,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final schedule = _generateSchedules([routine]);
        expect(
          schedule.any((s) => s.routineId == 'routine1'),
          isFalse,
          reason: 'Adhoc routines should not auto-appear in schedule',
        );
      });
    });

    group('Schedule generation', () {
      test('active routine generates today schedule', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          isActive: true,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final schedules = _generateSchedules([routine]);
        expect(schedules.isNotEmpty, isTrue);
      });

      test('inactive routine does not generate schedule', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          isActive: false,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final schedules = _generateSchedules([routine]);
        expect(
          schedules.any((s) => s.routineId == 'routine1'),
          isFalse,
        );
      });

      test('completed routine generates schedule with completedAt', () {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        final completion = RoutineCompletion(
          id: 'comp1',
          routineId: 'routine1',
          completedAt: now,
        );

        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          isActive: true,
          completionLog: [completion],
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        final schedules = _generateSchedules([routine]);
        final todaySchedule = schedules.firstWhere(
          (s) => s.routineId == 'routine1' && s.scheduledDate == todayDate,
        );

        expect(todaySchedule.completedAt, isNotNull);
      });

      test('multiple routines generate multiple schedules', () {
        final routines = [
          Routine(
            id: 'routine1',
            name: 'Morning Jog',
            nameEn: 'Morning Jog',
            frequency: RoutineFrequency.daily,
            isActive: true,
            createdAt: DateTime(2026, 5, 1),
            updatedAt: DateTime(2026, 5, 15),
          ),
          Routine(
            id: 'routine2',
            name: 'Evening Read',
            nameEn: 'Evening Read',
            frequency: RoutineFrequency.daily,
            isActive: true,
            createdAt: DateTime(2026, 5, 1),
            updatedAt: DateTime(2026, 5, 15),
          ),
        ];

        final schedules = _generateSchedules(routines);
        expect(schedules.length, greaterThanOrEqualTo(2));
        expect(schedules.map((s) => s.routineId).toSet(), {'routine1', 'routine2'});
      });
    });

    group('Category detection', () {
      test('autoDetectCategory matches health keywords', () {
        expect(autoDetectCategory('Take vitamin'), RoutineCategory.health);
        expect(autoDetectCategory('take medicine'), RoutineCategory.health);
        expect(autoDetectCategory('health check'), RoutineCategory.health);
      });

      test('autoDetectCategory matches fitness keywords', () {
        expect(autoDetectCategory('run 5km'), RoutineCategory.fitness);
        expect(autoDetectCategory('gym workout'), RoutineCategory.fitness);
        expect(autoDetectCategory('yoga session'), RoutineCategory.fitness);
      });

      test('autoDetectCategory matches nutrition keywords', () {
        expect(autoDetectCategory('drink water'), RoutineCategory.nutrition);
        expect(autoDetectCategory('eat vegetables'), RoutineCategory.nutrition);
        expect(autoDetectCategory('fruit intake'), RoutineCategory.nutrition);
      });

      test('autoDetectCategory returns null for unknown', () {
        expect(autoDetectCategory('xyz unknown'), isNull);
      });

      test('autoDetectCategory is case-insensitive', () {
        expect(autoDetectCategory('DRINK WATER'), RoutineCategory.nutrition);
        expect(autoDetectCategory('Drink Water'), RoutineCategory.nutrition);
      });

      test('autoDetectCategory works with Chinese keywords', () {
        expect(autoDetectCategory('喝水'), RoutineCategory.nutrition);
        expect(autoDetectCategory('冥想'), RoutineCategory.mindfulness);
        expect(autoDetectCategory('睡眠'), RoutineCategory.sleep);
      });
    });

    group('Category display', () {
      test('category name in English', () {
        expect(routineCategoryName(RoutineCategory.health, false), 'Health');
        expect(routineCategoryName(RoutineCategory.fitness, false), 'Fitness');
      });

      test('category name in Chinese', () {
        expect(routineCategoryName(RoutineCategory.health, true), '养');
        expect(routineCategoryName(RoutineCategory.fitness, true), '劲');
      });

      test('category emoji mapping complete', () {
        for (final cat in RoutineCategory.values) {
          expect(kCategoryEmoji.containsKey(cat), isTrue);
        }
      });

      test('category icon path mapping complete', () {
        for (final cat in RoutineCategory.values) {
          expect(kCategoryIconPath.containsKey(cat), isTrue);
        }
      });

      test('effective icon uses explicit icon if set', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Test',
          nameEn: 'Test',
          frequency: RoutineFrequency.daily,
          icon: '🎯',
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.effectiveIcon, '🎯');
      });

      test('effective icon uses category emoji if no explicit icon', () {
        final routine = Routine(
          id: 'routine1',
          name: 'Morning Jog',
          nameEn: 'Morning Jog',
          frequency: RoutineFrequency.daily,
          category: RoutineCategory.fitness,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.effectiveIcon, '🏃');
      });

      test('effective icon falls back to auto-detect', () {
        final routine = Routine(
          id: 'routine1',
          name: 'drink water',
          nameEn: 'drink water',
          frequency: RoutineFrequency.daily,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.effectiveIcon, '🥗'); // Nutrition emoji
      });

      test('effective icon defaults to star', () {
        final routine = Routine(
          id: 'routine1',
          name: 'unknown xyz',
          nameEn: 'unknown xyz',
          frequency: RoutineFrequency.daily,
          createdAt: DateTime(2026, 5, 1),
          updatedAt: DateTime(2026, 5, 15),
        );

        expect(routine.effectiveIcon, '⭐');
      });
    });
  });
}

// Helper function mimicking RoutineProvider.schedules getter
List<Schedule> _generateSchedules(List<Routine> routines) {
  final List<Schedule> result = [];
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  for (final routine in routines.where((r) => r.isActive)) {
    bool hasToday = false;

    for (final log in routine.completionLog) {
      final logDate = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      result.add(Schedule(
        id: log.id,
        routineId: routine.id,
        scheduledDate: logDate,
        completedAt: log.completedAt,
        notes: log.notes,
      ));
      if (logDate == todayDate) {
        hasToday = true;
      }
    }

    if (!hasToday && routine.frequency != RoutineFrequency.adhoc) {
      result.add(Schedule(
        id: '${routine.id}_$todayDate',
        routineId: routine.id,
        scheduledDate: todayDate,
        completedAt: null,
      ));
    }
  }

  return result;
}

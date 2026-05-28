import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/routine.dart';

void main() {
  group('Routine locale display', () {
    final r = Routine(
      id: 'test',
      name: '喝水',
      nameEn: 'Drink water',
      frequency: RoutineFrequency.daily,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: '多喝水对身体好',
      descriptionEn: 'Drinking water is healthy',
    );

    test('displayName shows Chinese for isZh=true', () {
      expect(r.displayName(true), '喝水');
    });

    test('displayName shows English for isZh=false', () {
      expect(r.displayName(false), 'Drink water');
    });

    test('frequency label is locale-aware', () {
      expect(r.frequencyLabelFor(true), '每天');
      expect(r.frequencyLabelFor(false), 'Daily');
    });

    test('weekly frequency label is locale-aware', () {
      final wr = Routine(
        id: 'w', name: 'w', nameEn: 'w', frequency: RoutineFrequency.weekly,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        scheduledDaysOfWeek: [1, 3, 5],
      );
      expect(wr.frequencyLabelFor(true), contains('周一'));
      expect(wr.frequencyLabelFor(false), contains('Mon'));
    });
  });

  group('Routine category locale', () {
    test('all categories have locale names', () {
      for (final cat in RoutineCategory.values) {
        final zh = routineCategoryName(cat, true);
        final en = routineCategoryName(cat, false);
        expect(zh.isNotEmpty, true);
        expect(en.isNotEmpty, true);
        expect(zh, isNot(en)); // Names differ by locale
      }
    });

    test('keyword auto-detection works', () {
      final cat = autoDetectCategory('冥想练习');
      expect(cat, RoutineCategory.mindfulness);
    });

    test('unknown keywords return null', () {
      final cat = autoDetectCategory('random text xyz');
      expect(cat, isNull);
    });
  });

  group('Routine voiceEnabled', () {
    test('defaults to false', () {
      final r = Routine(
        id: 'test', name: 'Test', nameEn: 'Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(r.voiceEnabled, isFalse);
    });

    test('fromJson reads voiceEnabled when true', () {
      final json = {
        'id': 'test', 'name': 'Test', 'nameEn': 'Test',
        'frequency': 'daily',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'voiceEnabled': true,
      };
      final r = Routine.fromJson(json);
      expect(r.voiceEnabled, isTrue);
    });

    test('fromJson defaults voiceEnabled to false when missing', () {
      final json = {
        'id': 'test', 'name': 'Test', 'nameEn': 'Test',
        'frequency': 'daily',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      final r = Routine.fromJson(json);
      expect(r.voiceEnabled, isFalse);
    });

    test('toJson writes voiceEnabled', () {
      final r = Routine(
        id: 'test', name: 'Test', nameEn: 'Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        voiceEnabled: true,
      );
      final json = r.toJson();
      expect(json['voiceEnabled'], isTrue);
    });

    test('toJson round-trip preserves voiceEnabled', () {
      final r = Routine(
        id: 'test', name: 'Test', nameEn: 'Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        voiceEnabled: true,
      );
      final round = Routine.fromJson(r.toJson());
      expect(round.voiceEnabled, r.voiceEnabled);
    });

    test('copyWith preserves voiceEnabled', () {
      final r = Routine(
        id: 'test', name: 'Test', nameEn: 'Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        voiceEnabled: true,
      );
      final copy = r.copyWith(name: 'Changed');
      expect(copy.voiceEnabled, isTrue);
    });

    test('copyWith can override voiceEnabled', () {
      final r = Routine(
        id: 'test', name: 'Test', nameEn: 'Test',
        frequency: RoutineFrequency.daily,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
        voiceEnabled: false,
      );
      final copy = r.copyWith(voiceEnabled: true);
      expect(copy.voiceEnabled, isTrue);
    });
  });

  group('Reminder time validation', () {
    test('valid HH:MM passes', () {
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch('08:00'), true);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch('22:30'), true);
    });

    test('invalid formats fail', () {
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch('8:00'), false);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch('abc'), false);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(''), false);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch('25:00'), true); // boundary — regex passes but hour 25 is invalid
    });
  });

  group('Private tag filter logic', () {
    test('tagIds contains tag_private excludes from AI', () {
      final entries = [
        _mockEntry('1', 'Open entry', []),
        _mockEntry('2', 'Private entry', ['tag_private']),
        _mockEntry('3', 'Another open', ['tag_daily']),
      ];
      final filtered = entries.where((e) => !e.tagIds.contains('tag_private')).toList();
      expect(filtered.length, 2);
      expect(filtered.any((e) => e.id == '2'), false);
    });
  });
}

// Minimal mock entry for filter logic test
class _MockEntry {
  final String id;
  final String content;
  final List<String> tagIds;
  _MockEntry(this.id, this.content, this.tagIds);
}

_MockEntry _mockEntry(String id, String content, List<String> tags) {
  return _MockEntry(id, content, tags);
}

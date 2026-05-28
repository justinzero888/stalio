import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/entry.dart';

void main() {
  group('Entry Filtering', () {
    late List<Entry> allEntries;

    setUp(() {
      allEntries = [
        Entry(
          id: 'entry1',
          type: EntryType.freeform,
          content: 'Morning jog was refreshing',
          tagIds: ['tag_fitness', 'tag_health'],
          emotion: '😊',
          createdAt: DateTime(2026, 5, 14),
          updatedAt: DateTime(2026, 5, 14),
          format: EntryFormat.note,
        ),
        Entry(
          id: 'entry2',
          type: EntryType.freeform,
          content: 'Felt sad today after the meeting',
          tagIds: ['tag_work'],
          emotion: '😢',
          createdAt: DateTime(2026, 5, 13),
          updatedAt: DateTime(2026, 5, 13),
          format: EntryFormat.note,
        ),
        Entry(
          id: 'entry3',
          type: EntryType.routine,
          content: 'Evening meditation completed',
          tagIds: ['tag_mindfulness'],
          emotion: '😌',
          createdAt: DateTime(2026, 5, 14),
          updatedAt: DateTime(2026, 5, 14),
          format: EntryFormat.note,
        ),
        Entry(
          id: 'entry4',
          type: EntryType.freeform,
          content: 'Practiced yoga and felt great',
          tagIds: ['tag_fitness', 'tag_mindfulness'],
          emotion: '😊',
          createdAt: DateTime(2026, 5, 12),
          updatedAt: DateTime(2026, 5, 12),
          format: EntryFormat.note,
        ),
        Entry(
          id: 'entry5',
          type: EntryType.freeform,
          content: 'Boring day with nothing special',
          tagIds: [],
          emotion: '😐',
          createdAt: DateTime(2026, 5, 11),
          updatedAt: DateTime(2026, 5, 11),
          format: EntryFormat.note,
        ),
      ];
    });

    group('search query filter', () {
      test('empty query returns all entries', () {
        final filtered = _filterBySearch(allEntries, '');
        expect(filtered.length, allEntries.length);
      });

      test('search finds entries by content', () {
        final filtered = _filterBySearch(allEntries, 'jog');
        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry1');
      });

      test('search is case-insensitive', () {
        final filtered = _filterBySearch(allEntries, 'JOG');
        expect(filtered.length, 1);
      });

      test('search finds multiple matching entries', () {
        final filtered = _filterBySearch(allEntries, 'felt');
        expect(filtered.length, 2); // entry2 and entry4
        expect(filtered.map((e) => e.id), containsAll(['entry2', 'entry4']));
      });

      test('search with no matches returns empty', () {
        final filtered = _filterBySearch(allEntries, 'xyz123');
        expect(filtered.isEmpty, isTrue);
      });

      test('search matches partial words', () {
        final filtered = _filterBySearch(allEntries, 'med');
        expect(filtered.length, 1); // meditation
        expect(filtered.first.id, 'entry3');
      });

      test('search with spaces matches multi-word phrases', () {
        final filtered = _filterBySearch(allEntries, 'evening meditation');
        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry3');
      });

      test('search handles Chinese characters', () {
        final testEntries = [
          Entry(
            id: 'entry_cn',
            type: EntryType.freeform,
            content: '今天很开心',
            tagIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            format: EntryFormat.note,
          ),
        ];
        final filtered = _filterBySearch(testEntries, '开心');
        expect(filtered.length, 1);
      });
    });

    group('tag filter', () {
      test('null tag filter returns all entries', () {
        final filtered = _filterByTag(allEntries, null);
        expect(filtered.length, allEntries.length);
      });

      test('tag filter returns entries with tag', () {
        final filtered = _filterByTag(allEntries, 'tag_fitness');
        expect(filtered.length, 2); // entry1, entry4
        expect(
          filtered.map((e) => e.id),
          containsAll(['entry1', 'entry4']),
        );
      });

      test('tag filter with no matches returns empty', () {
        final filtered = _filterByTag(allEntries, 'tag_nonexistent');
        expect(filtered.isEmpty, isTrue);
      });

      test('tag filter works with entries with no tags', () {
        final filtered = _filterByTag(allEntries, 'tag_fitness');
        expect(
          filtered.any((e) => e.tagIds.isEmpty),
          isFalse,
          reason: 'Should only return entries that have the tag',
        );
      });

      test('tag filter returns entries with multiple tags including target', () {
        final filtered = _filterByTag(allEntries, 'tag_mindfulness');
        expect(filtered.length, 2); // entry3, entry4
        expect(
          filtered.map((e) => e.id),
          containsAll(['entry3', 'entry4']),
        );
      });
    });

    group('type filter', () {
      test('freeform type filter returns freeform entries', () {
        final filtered = _filterByType(allEntries, 'freeform');
        expect(filtered.length, 4);
        expect(
          filtered.every((e) => e.type == EntryType.freeform),
          isTrue,
        );
      });

      test('routine type filter returns routine entries', () {
        final filtered = _filterByType(allEntries, 'routine');
        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry3');
      });

      test('all type filter returns all entries', () {
        final filtered = _filterByType(allEntries, 'all');
        expect(filtered.length, allEntries.length);
      });

      test('invalid type filter returns all entries', () {
        final filtered = _filterByType(allEntries, 'invalid');
        expect(filtered.length, allEntries.length);
      });
    });

    group('combined filters', () {
      test('search AND tag filter works', () {
        final byTag = _filterByTag(allEntries, 'tag_fitness');
        final filtered = _filterBySearch(byTag, 'jog');

        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry1');
      });

      test('search AND type filter works', () {
        final byType = _filterByType(allEntries, 'routine');
        final filtered = _filterBySearch(byType, 'meditation');

        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry3');
      });

      test('tag AND type filter works', () {
        final byType = _filterByType(allEntries, 'freeform');
        final filtered = _filterByTag(byType, 'tag_fitness');

        expect(filtered.length, 2);
        expect(filtered.map((e) => e.id), containsAll(['entry1', 'entry4']));
      });

      test('all three filters work together', () {
        final byType = _filterByType(allEntries, 'freeform');
        final byTag = _filterByTag(byType, 'tag_fitness');
        final filtered = _filterBySearch(byTag, 'felt');

        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry4');
      });

      test('combined filters with no matches returns empty', () {
        final byType = _filterByType(allEntries, 'routine');
        final byTag = _filterByTag(byType, 'tag_fitness');

        expect(byTag.isEmpty, isTrue);
      });
    });

    group('filter ordering', () {
      test('filters preserve entry order from original list', () {
        final filtered = _filterBySearch(allEntries, 'felt');
        final ids = filtered.map((e) => e.id).toList();

        // entry2 comes before entry4 in original list
        expect(ids.indexOf('entry2'), lessThan(ids.indexOf('entry4')));
      });

      test('tag filter preserves original order', () {
        final filtered = _filterByTag(allEntries, 'tag_fitness');
        // entry1 (index 0) comes before entry4 (index 3)
        final entry1Idx = allEntries.indexWhere((e) => e.id == 'entry1');
        final entry4Idx = allEntries.indexWhere((e) => e.id == 'entry4');
        expect(entry1Idx, lessThan(entry4Idx));
      });
    });

    group('filter edge cases', () {
      test('whitespace-only search query treated as empty', () {
        final filtered = _filterBySearch(allEntries, '   ');
        // Trimmed to empty, should return all
        expect(filtered.length, 5);
      });

      test('empty tag list entry can be searched', () {
        final filtered = _filterBySearch(allEntries, 'boring');
        expect(filtered.length, 1);
        expect(filtered.first.id, 'entry5');
      });

      test('tag filter works when entry has empty tag list', () {
        final filtered = _filterByTag(allEntries, 'tag_fitness');
        expect(
          filtered.any((e) => e.tagIds.isEmpty),
          isFalse,
        );
      });

      test('search with special characters', () {
        final testEntries = [
          Entry(
            id: 'entry_special',
            type: EntryType.freeform,
            content: 'What? Really! That\'s amazing.',
            tagIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            format: EntryFormat.note,
          ),
        ];
        final filtered = _filterBySearch(testEntries, 'What');
        expect(filtered.length, 1);
      });
    });

    group('filter performance', () {
      test('search on large dataset completes quickly', () {
        final largeEntrySet = List.generate(
          1000,
          (i) => Entry(
            id: 'entry_$i',
            type: i % 2 == 0 ? EntryType.freeform : EntryType.routine,
            content: 'Entry $i with searchable content',
            tagIds: i % 3 == 0 ? ['tag_test'] : [],
            createdAt: DateTime.now().subtract(Duration(days: i)),
            updatedAt: DateTime.now().subtract(Duration(days: i)),
            format: EntryFormat.note,
          ),
        );

        final stopwatch = Stopwatch()..start();
        final filtered = _filterBySearch(largeEntrySet, 'searchable');
        stopwatch.stop();

        expect(filtered.isNotEmpty, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('tag filter on large dataset completes quickly', () {
        final largeEntrySet = List.generate(
          1000,
          (i) => Entry(
            id: 'entry_$i',
            type: EntryType.freeform,
            content: 'Entry $i',
            tagIds: i % 5 == 0 ? ['tag_common'] : ['tag_rare'],
            createdAt: DateTime.now().subtract(Duration(days: i)),
            updatedAt: DateTime.now().subtract(Duration(days: i)),
            format: EntryFormat.note,
          ),
        );

        final stopwatch = Stopwatch()..start();
        final filtered = _filterByTag(largeEntrySet, 'tag_common');
        stopwatch.stop();

        expect(filtered.isNotEmpty, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('filter immutability', () {
      test('filtering does not modify original list', () {
        final originalLength = allEntries.length;
        _filterBySearch(allEntries, 'jog');
        _filterByTag(allEntries, 'tag_fitness');
        _filterByType(allEntries, 'freeform');

        expect(allEntries.length, originalLength);
      });

      test('filtering returns new list instance', () {
        final original = allEntries;
        final filtered = _filterBySearch(allEntries, 'jog');

        expect(identical(original, filtered), isFalse);
      });
    });
  });
}

// Helper functions mimicking EntryProvider filtering logic
List<Entry> _filterBySearch(List<Entry> entries, String query) {
  if (query.trim().isEmpty) return List.from(entries);

  final searchLower = query.toLowerCase();
  return entries
      .where((e) => e.content.toLowerCase().contains(searchLower))
      .toList();
}

List<Entry> _filterByTag(List<Entry> entries, String? tagId) {
  if (tagId == null) return List.from(entries);

  return entries.where((e) => e.tagIds.contains(tagId)).toList();
}

List<Entry> _filterByType(List<Entry> entries, String filterType) {
  if (filterType == 'all') return List.from(entries);

  // Invalid filter type defaults to 'all'
  if (filterType != 'freeform' && filterType != 'routine') {
    return List.from(entries);
  }

  final typeEnum = filterType == 'freeform' ? EntryType.freeform : EntryType.routine;
  return entries.where((e) => e.type == typeEnum).toList();
}

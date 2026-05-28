import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/entry.dart';

void main() {
  group('Entry serialization with list items', () {
    test('list entry survives toJson/fromJson round-trip', () {
      final original = Entry(
        id: 'test-1',
        type: EntryType.freeform,
        content: 'Daily Tasks',
        format: EntryFormat.list,
        listItems: [
          ListItem(id: 'a', text: 'Buy milk', isDone: false, sortOrder: 0),
          ListItem(id: 'b', text: 'Walk dog', isDone: true, sortOrder: 1),
        ],
        listCarriedForward: false,
        createdAt: DateTime(2026, 4, 30, 10, 0),
        updatedAt: DateTime(2026, 4, 30, 10, 0),
        emotion: '😊',
      );

      final json = original.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.format, EntryFormat.list);
      expect(restored.listItems!.length, 2);
      expect(restored.listItems![0].text, 'Buy milk');
      expect(restored.listItems![0].isDone, false);
      expect(restored.listItems![1].text, 'Walk dog');
      expect(restored.listItems![1].isDone, true);
      expect(restored.listCarriedForward, false);
      expect(restored.emotion, '😊');
      expect(restored.content, 'Daily Tasks');
      expect(restored.type, EntryType.freeform);
    });

    test('note entry round-trip with defaults', () {
      final original = Entry(
        id: 'note-1',
        type: EntryType.freeform,
        content: 'A simple note',
        format: EntryFormat.note,
        createdAt: DateTime(2026, 4, 30),
        updatedAt: DateTime(2026, 4, 30),
      );

      final json = original.toJson();
      final restored = Entry.fromJson(json);

      expect(restored.format, EntryFormat.note);
      expect(restored.listItems, isNull);
      expect(restored.listCarriedForward, false);
    });

    test('fromJson handles missing format field (backward compat)', () {
      final json = {
        'id': 'legacy-1',
        'type': 'freeform',
        'content': 'Old note',
        'tagIds': <String>[],
        'mediaUrls': <String>[],
        'createdAt': '2026-04-30T10:00:00.000',
        'updatedAt': '2026-04-30T10:00:00.000',
      };

      final entry = Entry.fromJson(json);
      expect(entry.format, EntryFormat.note);
      expect(entry.listItems, isNull);
      expect(entry.listCarriedForward, false);
    });

    test('listItems survives null and empty cases', () {
      final entry = Entry.fromJson({
        'id': 'test',
        'type': 'freeform',
        'content': '',
        'tagIds': <String>[],
        'mediaUrls': <String>[],
        'createdAt': '2026-04-30T10:00:00.000',
        'updatedAt': '2026-04-30T10:00:00.000',
        'format': 'list',
        'listItems': null,
        'listCarriedForward': false,
      });

      expect(entry.listItems, isNull);
      expect(entry.format, EntryFormat.list);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:blinking/models/list_item.dart';

void main() {
  group('ListItem', () {
    group('fromJson / toJson round-trip', () {
      test('serializes and deserializes correctly', () {
        final original = ListItem(id: '1', text: 'Buy milk', isDone: false, sortOrder: 0);
        final json = original.toJson();
        final restored = ListItem.fromJson(json);
        expect(restored.id, '1');
        expect(restored.text, 'Buy milk');
        expect(restored.isDone, false);
        expect(restored.sortOrder, 0);
      });

      test('preserves isDone = true', () {
        final original = ListItem(id: 'a', text: 'Done task', isDone: true, sortOrder: 3);
        final restored = ListItem.fromJson(original.toJson());
        expect(restored.isDone, true);
      });
    });

    group('listFromJson', () {
      test('returns empty list for null input', () {
        expect(ListItem.listFromJson(null), []);
      });

      test('returns empty list for empty string', () {
        expect(ListItem.listFromJson(''), []);
      });

      test('parses valid JSON array', () {
        const json = '[{"id":"1","text":"Item 1","is_done":false,"sort_order":0},'
            '{"id":"2","text":"Item 2","is_done":true,"sort_order":1}]';
        final items = ListItem.listFromJson(json);
        expect(items.length, 2);
        expect(items[0].id, '1');
        expect(items[0].text, 'Item 1');
        expect(items[1].isDone, true);
      });
    });

    group('listToJson', () {
      test('returns null for null input', () {
        expect(ListItem.listToJson(null), null);
      });

      test('returns null for empty list', () {
        expect(ListItem.listToJson([]), null);
      });

      test('serializes populated list', () {
        final items = [
          ListItem(id: '1', text: 'A', sortOrder: 0),
          ListItem(id: '2', text: 'B', sortOrder: 1),
        ];
        final json = ListItem.listToJson(items);
        expect(json, isNotNull);
        final parsed = ListItem.listFromJson(json);
        expect(parsed.length, 2);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final original = ListItem(id: '1', text: 'Original', isDone: false, sortOrder: 0);
        final copy = original.copyWith();
        expect(copy.id, '1');
        expect(copy.text, 'Original');
        expect(copy.isDone, false);
        expect(copy.sortOrder, 0);
      });

      test('updates only specified fields', () {
        final original = ListItem(id: '1', text: 'Original', isDone: false, sortOrder: 0);
        final copy = original.copyWith(text: 'Changed', isDone: true, sortOrder: 5);
        expect(copy.text, 'Changed');
        expect(copy.isDone, true);
        expect(copy.sortOrder, 5);
        expect(copy.id, '1');
      });
    });

    group('equality', () {
      test('same values are equal', () {
        final a = ListItem(id: '1', text: 'Test', sortOrder: 0);
        final b = ListItem(id: '1', text: 'Test', sortOrder: 0);
        expect(a, equals(b));
      });

      test('different values are not equal', () {
        final a = ListItem(id: '1', text: 'Test', sortOrder: 0);
        final b = ListItem(id: '2', text: 'Other', sortOrder: 0);
        expect(a, isNot(equals(b)));
      });
    });

    group('validation', () {
      test('rejects empty text', () {
        expect(
          () => ListItem(id: '1', text: '', sortOrder: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('rejects text longer than 200 chars', () {
        expect(
          () => ListItem(id: '1', text: 'x' * 201, sortOrder: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts text exactly 200 chars', () {
        final item = ListItem(id: '1', text: 'x' * 200, sortOrder: 0);
        expect(item.text.length, 200);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stalio/models/entry.dart';
import 'package:stalio/core/utils/share_format.dart';

void main() {
  final testEntries = [
    Entry(
      id: 'e1', type: EntryType.freeform, content: 'Hello world', tagIds: [],
      createdAt: DateTime(2026, 6, 1, 10, 30), updatedAt: DateTime(2026, 6, 1),
    ),
    Entry(
      id: 'e2', type: EntryType.freeform, content: 'Second entry\nwith multiple lines', tagIds: [],
      emotion: '😊', createdAt: DateTime(2026, 6, 2, 14, 0), updatedAt: DateTime(2026, 6, 2),
    ),
  ];

  group('ShareFormat — Plain text', () {
    test('includes entry content', () {
      final result = ShareFormat.toPlainText(testEntries, false);
      expect(result, contains('Hello world'));
      expect(result, contains('Second entry'));
    });

    test('includes date in English format', () {
      final result = ShareFormat.toPlainText(testEntries, false);
      expect(result, contains('Jun 1, 2026'));
    });

    test('includes date in Chinese format', () {
      final result = ShareFormat.toPlainText(testEntries, true);
      expect(result, contains('2026年6月1日'));
    });
  });

  group('ShareFormat — Markdown', () {
    test('has title header', () {
      final result = ShareFormat.toMarkdown(testEntries, false);
      expect(result, contains('# Stalio Notes'));
    });

    test('has entry date as subheader', () {
      final result = ShareFormat.toMarkdown(testEntries, false);
      expect(result, contains('## Jun 1, 2026'));
      expect(result, contains('## Jun 2, 2026'));
    });

    test('includes mood when present', () {
      final result = ShareFormat.toMarkdown(testEntries, false);
      expect(result, contains('*Mood: 😊*'));
    });
  });

  group('ShareFormat — Rich text', () {
    test('has header section', () {
      final result = ShareFormat.toRichText(testEntries, false);
      expect(result, contains('STALIO NOTES'));
      expect(result, contains('═════════════'));
    });

    test('has box-drawing borders around entries', () {
      final result = ShareFormat.toRichText(testEntries, false);
      expect(result, contains('┌─'));
      expect(result, contains('│ Hello world'));
      expect(result, contains('└'));
    });

    test('handles multiline content', () {
      final result = ShareFormat.toRichText(testEntries, false);
      expect(result, contains('│ Second entry'));
      expect(result, contains('│ with multiple lines'));
    });
  });
}

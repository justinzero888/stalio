import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinking/models/entry.dart';
import 'package:blinking/models/tag.dart';
import 'package:blinking/providers/entry_provider.dart';
import 'package:blinking/providers/locale_provider.dart';
import 'package:blinking/providers/tag_provider.dart';
import 'package:blinking/providers/card_provider.dart';
import 'package:blinking/repositories/entry_repository.dart';
import 'package:blinking/repositories/tag_repository.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/screens/moment/entry_detail_screen.dart';

/// Fake StorageService — no platform channels needed.
class _FakeStorage extends StorageService {
  @override
  Future<List<Tag>> getTags() async => [];

  @override
  Future<List<Entry>> getEntries() async => [];
}

TagProvider _tagProvider() {
  final p = TagProvider(TagRepository(_FakeStorage()));
  p.loadTagsForTest([]);
  return p;
}

EntryProvider _entryProvider({List<Entry> entries = const []}) {
  final p = EntryProvider(EntryRepository(_FakeStorage()));
  // Seed with the provided entries so the provider has data without platform channels
  for (final e in entries) {
    p.allEntries; // access getter to ensure list is initialized
  }
  return p;
}

Widget _wrap(Widget child, {List<Entry> entries = const []}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => _tagProvider()),
      ChangeNotifierProvider(create: (_) => _entryProvider(entries: entries)),
      ChangeNotifierProvider(create: (_) => CardProvider(_FakeStorage())..loadForTest()),
    ],
    child: MaterialApp(home: child),
  );
}

Entry _entry({String content = 'Hello memory', String? emotion}) => Entry(
      id: 'e1',
      type: EntryType.freeform,
      content: content,
      createdAt: DateTime(2026, 4, 22, 9, 30),
      updatedAt: DateTime(2026, 4, 22, 9, 30),
      emotion: emotion,
    );

void main() {
  group('EntryDetailScreen', () {
    testWidgets('displays entry content', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.text('Hello memory'), findsOneWidget);
    });

    testWidgets('displays emotion emoji when present', (tester) async {
      await tester.pumpWidget(
          _wrap(EntryDetailScreen(entry: _entry(emotion: '😊'))));
      await tester.pump();
      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('no emotion widget when emotion is null', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.text('😊'), findsNothing);
    });

    testWidgets('Edit button is present in AppBar', (tester) async {
      final todayEntry = Entry(
        id: 'e2',
        type: EntryType.freeform,
        content: 'Today entry',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: todayEntry)));
      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('Share button is present in AppBar', (tester) async {
      await tester.pumpWidget(_wrap(EntryDetailScreen(entry: _entry())));
      await tester.pump();
      expect(find.byIcon(Icons.share), findsOneWidget);
    });
  });
}

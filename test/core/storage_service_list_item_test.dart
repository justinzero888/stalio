import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:blinking/core/services/storage_service.dart';
import 'package:blinking/core/services/database_service.dart';
import 'package:blinking/models/entry.dart';
import 'package:blinking/repositories/entry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _MockPathProvider extends FakePathProvider {
  final String appDocsPath;
  _MockPathProvider(this.appDocsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => appDocsPath;

  @override
  Future<String?> getTemporaryPath() async => appDocsPath;
}

class FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => throw UnimplementedError();
  @override
  Future<String?> getApplicationCachePath() async => throw UnimplementedError();
  @override
  Future<String?> getApplicationSupportPath() async => throw UnimplementedError();
  @override
  Future<String?> getTemporaryPath() async => throw UnimplementedError();
  @override
  Future<String?> getExternalStoragePath() async => throw UnimplementedError();
  @override
  Future<List<String>?> getExternalCachePaths() async => throw UnimplementedError();
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async =>
      throw UnimplementedError();
  @override
  Future<String?> getDownloadsPath() async => throw UnimplementedError();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('StorageService — list item CRUD', () {
    late Directory tempDir;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('list_item_crud_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storageService = StorageService();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('toggleListItem flips isDone on selected item', () async {
      final entry = Entry(
        id: 'toggle-1', type: EntryType.freeform, content: 'Toggle Test',
        format: EntryFormat.list,
        listItems: [ListItem(id: 'a', text: 'Buy milk', isDone: false, sortOrder: 0)],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storageService.addEntry(entry);
      await storageService.toggleListItem('toggle-1', 'a');
      final entries = await storageService.getEntries();
      expect(entries.firstWhere((e) => e.id == 'toggle-1').listItems!.first.isDone, true);
    });

    test('toggleListItem on non-existent entry does nothing', () async {
      await storageService.toggleListItem('nonexistent', 'a');
    });

    test('toggleListItem toggles back to false', () async {
      final entry = Entry(
        id: 'toggle-2', type: EntryType.freeform, content: 'Toggle Back',
        format: EntryFormat.list,
        listItems: [ListItem(id: 'a', text: 'Task', isDone: true, sortOrder: 0)],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storageService.addEntry(entry);
      await storageService.toggleListItem('toggle-2', 'a');
      final entries = await storageService.getEntries();
      expect(entries.firstWhere((e) => e.id == 'toggle-2').listItems!.first.isDone, false);
    });

    test('markListCarriedForward sets flag', () async {
      final entry = Entry(
        id: 'mark-1', type: EntryType.freeform, content: 'Mark Test',
        format: EntryFormat.list, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storageService.addEntry(entry);
      await storageService.markListCarriedForward('mark-1');
      final entries = await storageService.getEntries();
      expect(entries.firstWhere((e) => e.id == 'mark-1').listCarriedForward, true);
    });

    test('getEntries reads back list items and format', () async {
      final entry = Entry(
        id: 'read-1', type: EntryType.freeform, content: 'My Checklist',
        format: EntryFormat.list,
        listItems: [
          ListItem(id: 'a', text: 'Item 1', isDone: false, sortOrder: 0),
          ListItem(id: 'b', text: 'Item 2', isDone: true, sortOrder: 1),
        ],
        listCarriedForward: false, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storageService.addEntry(entry);
      final entries = await storageService.getEntries();
      final read = entries.firstWhere((e) => e.id == 'read-1');
      expect(read.format, EntryFormat.list);
      expect(read.listItems!.length, 2);
      expect(read.listItems![0].text, 'Item 1');
      expect(read.listItems![1].isDone, true);
      expect(read.listCarriedForward, false);
    });

    test('note entry has correct defaults', () async {
      final entry = Entry(
        id: 'note-1', type: EntryType.freeform, content: 'Just a note',
        format: EntryFormat.note, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      await storageService.addEntry(entry);
      final entries = await storageService.getEntries();
      final read = entries.firstWhere((e) => e.id == 'note-1');
      expect(read.format, EntryFormat.note);
      expect(read.listItems, isNull);
      expect(read.listCarriedForward, false);
    });
  });

  group('EntryRepository — checkAndCarryForward', () {
    late Directory tempDir;
    late StorageService storageService;
    late EntryRepository repository;

    setUp(() async {
      await DatabaseService.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      tempDir = Directory.systemTemp.createTempSync('carry_forward_');
      final appDocDir = Directory('${tempDir.path}/app_docs')..createSync(recursive: true);
      PathProviderPlatform.instance = _MockPathProvider(appDocDir.path);

      final db = await DatabaseService.createTestDatabase('${tempDir.path}/test.db');
      DatabaseService.setTestDatabase(db);

      storageService = StorageService();
      repository = EntryRepository(storageService);
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<void> _addEntry(DateTime date, String id, List<ListItem>? items,
        {bool carriedForward = false}) async {
      final entry = Entry(
        id: id, type: EntryType.freeform, content: 'Test List',
        format: EntryFormat.list, listItems: items,
        listCarriedForward: carriedForward, createdAt: date, updatedAt: date,
      );
      await storageService.addEntry(entry);
    }

    test('getYesterdayListEntry returns yesterday list', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await _addEntry(yesterday, 'yesterday-1', [
        ListItem(id: 'a', text: 'Item A', isDone: false, sortOrder: 0),
        ListItem(id: 'b', text: 'Item B', isDone: true, sortOrder: 1),
        ListItem(id: 'c', text: 'Item C', isDone: false, sortOrder: 2),
      ]);

      final entry = await repository.getYesterdayListEntry();
      expect(entry, isNotNull);
      expect(entry!.id, 'yesterday-1');

      final unchecked = repository.getUncheckedItems(entry);
      expect(unchecked.length, 2);
      expect(unchecked.every((i) => !i.isDone), true);
    });

    test('createTodayListWithItems creates today list', () async {
      final items = [
        ListItem(id: 'a', text: 'Item A', isDone: false, sortOrder: 0),
        ListItem(id: 'c', text: 'Item C', isDone: false, sortOrder: 1),
      ];
      final entry = await repository.createTodayListWithItems(items);
      expect(entry.format, EntryFormat.list);
      expect(entry.listItems!.length, 2);

      final all = await repository.getAll();
      final todayEntries = all.where((e) {
        final now = DateTime.now();
        final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
        final t = DateTime(now.year, now.month, now.day);
        return d == t && e.format == EntryFormat.list;
      }).toList();
      expect(todayEntries.length, 1);
    });

    test('getYesterdayListEntry returns null when all items done', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await _addEntry(yesterday, 'done-1', [
        ListItem(id: 'a', text: 'Done A', isDone: true, sortOrder: 0),
        ListItem(id: 'b', text: 'Done B', isDone: true, sortOrder: 1),
      ]);
      final entry = await repository.getYesterdayListEntry();
      expect(entry, isNotNull);
      final unchecked = repository.getUncheckedItems(entry!);
      expect(unchecked.isEmpty, true);
    });

    test('getYesterdayListEntry returns null for note entries', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final note = Entry(
        id: 'note-y-1', type: EntryType.freeform, content: 'A note',
        format: EntryFormat.note, createdAt: yesterday, updatedAt: yesterday,
      );
      await storageService.addEntry(note);
      final entry = await repository.getYesterdayListEntry();
      expect(entry, isNull);
    });

    test('hasTodayList returns true when today list exists', () async {
      await repository.createTodayListWithItems([
        ListItem(id: 'a', text: 'Today task', isDone: false, sortOrder: 0),
      ]);
      final allEntries = await repository.getAll();
      expect(repository.hasTodayList(allEntries), true);
    });

    test('getYesterdayListEntry does not return today entries', () async {
      await _addEntry(DateTime.now(), 'today-1',
          [ListItem(id: 'a', text: 'Today task', isDone: false, sortOrder: 0)]);
      final entry = await repository.getYesterdayListEntry();
      expect(entry, isNull);
    });
  });
}

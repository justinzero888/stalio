import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stalio/core/services/database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  group('DatabaseService — indexes', () {
    late String dbPath;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('db_index_test_');
      dbPath = '${dir.path}/test.db';
    });

    tearDown(() {
      final dir = Directory(File(dbPath).parent.path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<List<String>> _getIndexes(Database db, String table) async {
      final list = await db.rawQuery('PRAGMA index_list("$table")');
      return list.map((r) => r['name'] as String).toList();
    }

    test('fresh database has all required indexes', () async {
      final db = await DatabaseService.createTestDatabase(dbPath);

      final entryTagsIndexes = await _getIndexes(db, 'entry_tags');
      expect(
        entryTagsIndexes,
        contains('idx_entry_tags_entry_id'),
        reason: 'entry_tags table must have idx_entry_tags_entry_id',
      );
      expect(
        entryTagsIndexes,
        contains('idx_entry_tags_tag_id'),
        reason: 'entry_tags table must have idx_entry_tags_tag_id',
      );

      final entriesIndexes = await _getIndexes(db, 'entries');
      expect(
        entriesIndexes,
        contains('idx_entries_created_at'),
        reason: 'entries table must have idx_entries_created_at',
      );

      final completionsIndexes = await _getIndexes(db, 'completions');
      expect(
        completionsIndexes,
        contains('idx_completions_routine_id'),
        reason: 'completions table must have idx_completions_routine_id',
      );

      await db.close();
    });

    test('indexes query the correct columns', () async {
      final db = await DatabaseService.createTestDatabase(dbPath);

      final entryInfo = await db.rawQuery(
        "PRAGMA index_info('idx_entry_tags_entry_id')",
      );
      expect(entryInfo.length, 1);
      final col = entryInfo.first['name'] as String;
      expect(col, 'entry_id',
          reason: 'idx_entry_tags_entry_id must index the entry_id column');

      await db.close();
    });
  });
}

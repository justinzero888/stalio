import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stalio/core/services/database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 6: drop stale tables migration (v17→v18)', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('phase6_mig_');
      dbPath = '${tempDir.path}/test.db';
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('migration drops all 9 stale tables', () async {
      final db = await DatabaseService.createTestDatabase(dbPath, version: 17);
      // Manually create the stale tables that existed in v17 schemas
      await db.execute('CREATE TABLE IF NOT EXISTS ai_identity (id INTEGER PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS lens_sets (id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS active_lens_set (id INTEGER PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS ai_call_log (id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS trial_milestones (milestone TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS note_card_entries (card_id TEXT, entry_id TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS note_cards (id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS card_folders (id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE IF NOT EXISTS templates (id TEXT PRIMARY KEY)');
      final before = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final staleBefore = before.where((r) {
        final n = r['name'] as String;
        return ['ai_identity', 'lens_sets', 'active_lens_set', 'ai_call_log',
                'trial_milestones', 'templates', 'card_folders',
                'note_cards', 'note_card_entries'].contains(n);
      }).length;
      expect(staleBefore, greaterThan(0));
      await db.close();

      final db2 = await openDatabase(dbPath, version: 18, onUpgrade: (db, old, newV) async {
        await DatabaseService.runMigration(db, old);
      });

      final after = await db2.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final staleAfter = after.where((r) {
        final n = r['name'] as String;
        return ['ai_identity', 'lens_sets', 'active_lens_set', 'ai_call_log',
                'trial_milestones', 'templates', 'card_folders',
                'note_cards', 'note_card_entries'].contains(n);
      }).length;
      expect(staleAfter, 0);

      // Core tables preserved
      final coreTables = ['entries', 'tags', 'tag_categories', 'entry_tags', 'routines', 'completions'];
      for (final t in coreTables) {
        expect(after.any((r) => r['name'] == t), isTrue, reason: '$t should still exist');
      }

      await db2.close();
    });

    test('core table data preserved after migration', () async {
      final db = await DatabaseService.createTestDatabase(dbPath, version: 17);
      await db.execute("INSERT INTO entries (id, type, content, created_at, updated_at) VALUES ('e1', 'freeform', 'test', '2026-01-01', '2026-01-01')");
      await db.close();

      final db2 = await openDatabase(dbPath, version: 18, onUpgrade: (db, old, newV) async {
        await DatabaseService.runMigration(db, old);
      });

      final rows = await db2.query('entries', where: 'id = ?', whereArgs: ['e1']);
      expect(rows.length, 1);
      expect(rows.first['content'], 'test');
      await db2.close();
    });

    test('fresh install at v18 has only core tables', () async {
      final db = await DatabaseService.createTestDatabase(dbPath);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toList();
      expect(names, contains('completions'));
      expect(names, contains('entries'));
      expect(names, contains('entry_tags'));
      expect(names, contains('routines'));
      expect(names, contains('tag_categories'));
      expect(names, contains('tags'));

      // Stale tables absent
      expect(names.contains('ai_identity'), isFalse);
      expect(names.contains('templates'), isFalse);
      expect(names.contains('note_cards'), isFalse);

      await db.close();
    });
  });
}

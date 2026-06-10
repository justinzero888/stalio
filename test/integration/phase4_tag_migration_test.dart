import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stalio/core/services/database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 4: tag_category migration (v16 → v17)', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('phase4_mig_');
      dbPath = '${tempDir.path}/test.db';
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('migration adds category_id column to tags table', () async {
      final db = await DatabaseService.createTestDatabase(dbPath, version: 16);
      await db.execute("INSERT INTO tags (id, name, name_en, color, category, created_at) "
          "VALUES ('t1', 'Test', 'Test', '#000', 'custom', '2026-01-01')");
      await db.close();

      final db2 = await openDatabase(
        dbPath,
        version: 17,
        onUpgrade: (db, old, newV) async {
          await DatabaseService.runMigration(db, old);
        },
      );

      final columns = await db2.rawQuery("PRAGMA table_info('tags')");
      final colNames = columns.map((c) => c['name'] as String).toSet();
      expect(colNames.contains('category_id'), isTrue);
      expect(colNames.contains('category'), isTrue);

      final tables = await db2.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tag_categories'",
      );
      expect(tables, isNotEmpty);

      final rows = await db2.query('tags', where: 'id = ?', whereArgs: ['t1']);
      expect(rows.first['category_id'], isNull);
      expect(rows.first['category'], 'custom');

      await db2.close();
    });

    test('existing tag data is preserved after migration', () async {
      final db = await DatabaseService.createTestDatabase(dbPath, version: 16);
      await db.execute("INSERT INTO tags (id, name, name_en, color, category, created_at) VALUES "
          "('t_family', '家人', 'Family', '#FF9500', 'custom', '2025-06-01')");
      await db.execute("INSERT INTO tags (id, name, name_en, color, category, created_at) VALUES "
          "('t_private', '私密', 'Private', '#9E9E9E', 'system', '2025-06-01')");
      await db.close();

      final db2 = await openDatabase(dbPath, version: 17, onUpgrade: (db, old, newV) async {
        await DatabaseService.runMigration(db, old);
      });

      final tags = await db2.query('tags', orderBy: 'id ASC');
      expect(tags.length, 2);

      expect(tags[0]['id'], 't_family');
      expect(tags[0]['name'], '家人');
      expect(tags[0]['name_en'], 'Family');
      expect(tags[0]['color'], '#FF9500');
      expect(tags[0]['category'], 'custom');
      expect(tags[0]['category_id'], isNull);

      expect(tags[1]['id'], 't_private');
      expect(tags[1]['name'], '私密');
      expect(tags[1]['category'], 'system');
      expect(tags[1]['category_id'], isNull);

      await db2.close();
    });

    test('tag_categories table has correct schema after migration', () async {
      final db = await DatabaseService.createTestDatabase(dbPath, version: 16);
      await db.close();

      final db2 = await openDatabase(dbPath, version: 17, onUpgrade: (db, old, newV) async {
        await DatabaseService.runMigration(db, old);
      });

      final columns = await db2.rawQuery("PRAGMA table_info('tag_categories')");
      final colNames = columns.map((c) => {
        'name': c['name'] as String,
        'type': c['type'] as String,
        'notnull': c['notnull'] as int,
      }).toList();

      final byName = {for (final c in colNames) c['name'] as String: c};

      expect(byName['id']?['type'], 'TEXT');
      expect(byName['name']?['notnull'], 1);
      expect(byName['color']?['notnull'], 1);
      expect(byName['sort_order']?['type'], 'INTEGER');
      expect(byName['created_at']?['notnull'], 1);

      await db2.close();
    });
  });
}

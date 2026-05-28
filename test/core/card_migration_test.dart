import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:blinking/core/services/database_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService — v15 migration', () {
    late String dbPath;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('db_card_migration_');
      dbPath = '${dir.path}/test.db';
    });

    tearDown(() {
      final dir = Directory(File(dbPath).parent.path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<Database> _createV14Db() async {
      final db = await openDatabase(dbPath, version: 14);
      // Manually create the v14 schema (without v15 columns)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          font_family TEXT NOT NULL DEFAULT 'default',
          font_color TEXT NOT NULL DEFAULT '#222222',
          bg_color TEXT NOT NULL DEFAULT '#FFFFFF',
          is_built_in INTEGER NOT NULL DEFAULT 0,
          custom_image_path TEXT,
          source_template_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_cards (
          id TEXT PRIMARY KEY,
          template_id TEXT NOT NULL,
          folder_id TEXT NOT NULL,
          rendered_image_path TEXT,
          ai_summary TEXT,
          rich_content TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      // Insert old templates (simulate pre-v15 state)
      await db.insert('templates', {
        'id': 'tpl_spring',
        'name': '春日晴天',
        'icon': '🌸',
        'is_built_in': 1,
        'created_at': '2025-01-01T00:00:00.000',
      });
      await db.insert('templates', {
        'id': 'tpl_midnight',
        'name': '午夜蓝调',
        'icon': '🌙',
        'is_built_in': 1,
        'created_at': '2025-01-01T00:00:00.000',
      });
      return db;
    }

    test('migration from v14 to v15 adds new template columns', () async {
      final db = await _createV14Db();
      await DatabaseService.runMigration(db, 14);

      final columns = await db.rawQuery('PRAGMA table_info("templates")');
      final colNames = columns.map((c) => c['name'] as String).toList();
      expect(colNames, contains('name_en'));
      expect(colNames, contains('layout'));
      expect(colNames, contains('accent_color'));
      expect(colNames, contains('text_area_opacity'));
      expect(colNames, contains('text_backdrop_color'));
      expect(colNames, contains('footer_text'));
      expect(colNames, contains('show_mood'));
      expect(colNames, contains('show_date'));
      expect(colNames, contains('show_tags'));
      expect(colNames, contains('show_footer'));
      expect(colNames, contains('corner_style'));
      expect(colNames, contains('decoration_style'));

      await db.close();
    });

    test('migration from v14 to v15 adds new note_card columns', () async {
      final db = await _createV14Db();
      await DatabaseService.runMigration(db, 14);

      final columns = await db.rawQuery('PRAGMA table_info("note_cards")');
      final colNames = columns.map((c) => c['name'] as String).toList();
      expect(colNames, contains('card_content'));
      expect(colNames, contains('emotion'));
      expect(colNames, contains('display_tags'));
      expect(colNames, contains('show_mood'));
      expect(colNames, contains('show_date'));
      expect(colNames, contains('show_tags'));
      expect(colNames, contains('show_footer'));
      expect(colNames, contains('template_overrides'));

      await db.close();
    });

    test('migration replaces old templates with 8 new ones', () async {
      final db = await _createV14Db();
      await DatabaseService.runMigration(db, 14);

      final templates = await db.query('templates');
      expect(templates.length, 8);
      final ids = templates.map((t) => t['id'] as String).toList();
      expect(ids, contains('tpl_ink_rhythm'));
      expect(ids, contains('tpl_plain_paper'));
      expect(ids, contains('tpl_bamboo'));
      expect(ids, contains('tpl_moonlight'));
      expect(ids, contains('tpl_porcelain'));
      expect(ids, contains('tpl_tea'));
      expect(ids, contains('tpl_seal'));
      expect(ids, contains('tpl_landscape'));
      // Old IDs are gone
      expect(ids.where((id) => id.startsWith('tpl_spring') || id.startsWith('tpl_midnight')), isEmpty);

      await db.close();
    });

    test('migration preserves custom (non-built-in) templates', () async {
      final db = await _createV14Db();
      // Insert a custom template before migration
      await db.insert('templates', {
        'id': 'custom_user_template',
        'name': 'My Custom Style',
        'icon': '🎨',
        'is_built_in': 0,
        'created_at': '2025-06-01T00:00:00.000',
      });
      await DatabaseService.runMigration(db, 14);

      final templates = await db.query('templates');
      final ids = templates.map((t) => t['id'] as String).toList();
      // Custom template survives
      expect(ids, contains('custom_user_template'));
      // 1 custom + 8 built-in = 9 total
      expect(templates.length, 9);

      await db.close();
    });

    test('migration sets default values on new columns for existing note_cards', () async {
      final db = await _createV14Db();
      // Insert a note card before migration
      await db.insert('note_cards', {
        'id': 'card_old',
        'template_id': 'tpl_spring',
        'folder_id': 'folder_default',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-01T00:00:00.000',
      });
      await DatabaseService.runMigration(db, 14);

      final cards = await db.query('note_cards');
      expect(cards.length, 1);
      final card = cards.first;
      expect(card['show_mood'], 1);
      expect(card['show_date'], 1);
      expect(card['show_tags'], 1);
      expect(card['show_footer'], 1);
      expect(card['card_content'], isNull);
      expect(card['emotion'], isNull);

      await db.close();
    });

    test('fresh database at v15 has all required columns', () async {
      final db = await DatabaseService.createTestDatabase(dbPath);

      final tplColumns = await db.rawQuery('PRAGMA table_info("templates")');
      final tplColNames = tplColumns.map((c) => c['name'] as String).toList();
      expect(tplColNames, contains('name_en'));
      expect(tplColNames, contains('layout'));
      expect(tplColNames, contains('decoration_style'));
      expect(tplColNames, contains('show_mood'));
      expect(tplColNames, contains('show_footer'));

      final cardColumns = await db.rawQuery('PRAGMA table_info("note_cards")');
      final cardColNames = cardColumns.map((c) => c['name'] as String).toList();
      expect(cardColNames, contains('card_content'));
      expect(cardColNames, contains('emotion'));
      expect(cardColNames, contains('display_tags'));
      expect(cardColNames, contains('show_mood'));
      expect(cardColNames, contains('template_overrides'));

      await db.close();
    });
  });
}

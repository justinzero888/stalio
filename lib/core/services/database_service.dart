import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';

class DatabaseService {
  static const int kSchemaVersion = 16;
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Test-only: creates a fresh database at [path] with the full v12 schema.
  /// If [version] is provided, creates the DB at that version instead.
  /// Returns the raw Database so tests can inspect indexes.
  @visibleForTesting
  static Future<Database> createTestDatabase(String path, {int? version}) async {
    final targetVersion = version ?? 15;
    final db = await openDatabase(
      path,
      version: targetVersion,
      onCreate: (db, _) async {
        final svc = DatabaseService._internal();
        await svc._onCreate(db, targetVersion);
      },
    );
    return db;
  }

  /// Test-only: runs the onUpgrade migration on [db] from [oldVersion].
  @visibleForTesting
  static Future<void> runMigration(Database db, int oldVersion) async {
    final svc = DatabaseService._internal();
    await svc._onUpgrade(db, oldVersion, 15);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'blinking.db');

    return await openDatabase(
      path,
      version: DatabaseService.kSchemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE entries ADD COLUMN metadata_json TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN description_en TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE entries ADD COLUMN emotion TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN category TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS card_folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          font_family TEXT NOT NULL DEFAULT 'default',
          font_color TEXT NOT NULL DEFAULT '#222222',
          bg_color TEXT NOT NULL DEFAULT '#FFFFFF',
          is_built_in INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_cards (
          id TEXT PRIMARY KEY,
          template_id TEXT NOT NULL,
          folder_id TEXT NOT NULL,
          rendered_image_path TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_card_entries (
          card_id TEXT NOT NULL,
          entry_id TEXT NOT NULL,
          PRIMARY KEY (card_id, entry_id)
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT');
      await db.execute('ALTER TABLE routines ADD COLUMN scheduled_date TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE templates ADD COLUMN custom_image_path TEXT');
      await db.execute('ALTER TABLE note_cards ADD COLUMN ai_summary TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE note_cards ADD COLUMN rich_content TEXT');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE routines ADD COLUMN icon_image_path TEXT');
    }
    if (oldVersion < 9) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entry_tags_tag_id ON entry_tags(tag_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_completions_routine_id ON completions(routine_id)',
      );
    }
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE templates ADD COLUMN source_template_id TEXT');
    }
    if (oldVersion < 11) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entry_tags_entry_id ON entry_tags(entry_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_note_card_entries_card_id ON note_card_entries(card_id)',
      );
    }
    if (oldVersion < 12) {
      final columns = await db.rawQuery("PRAGMA table_info('entries')");
      final colNames = columns.map((c) => c['name'] as String).toList();
      if (!colNames.contains('entry_format')) {
        await db.execute(
          "ALTER TABLE entries ADD COLUMN entry_format TEXT NOT NULL DEFAULT 'note'",
        );
      }
      if (!colNames.contains('list_items')) {
        await db.execute(
          'ALTER TABLE entries ADD COLUMN list_items TEXT',
        );
      }
      if (!colNames.contains('list_carried_forward')) {
        await db.execute(
          'ALTER TABLE entries ADD COLUMN list_carried_forward INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_identity (
          id INTEGER PRIMARY KEY DEFAULT 1,
          avatar_emoji TEXT NOT NULL DEFAULT '\u2726',
          avatar_image_path TEXT,
          assistant_name TEXT NOT NULL DEFAULT 'Companion',
          personality_string TEXT NOT NULL DEFAULT 'Warm and grounded.',
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lens_sets (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL,
          lens_1 TEXT NOT NULL,
          lens_2 TEXT NOT NULL,
          lens_3 TEXT NOT NULL,
          is_builtin INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS active_lens_set (
          id INTEGER PRIMARY KEY DEFAULT 1,
          lens_set_id TEXT NOT NULL,
          activated_at TEXT NOT NULL,
          FOREIGN KEY (lens_set_id) REFERENCES lens_sets(id)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ai_call_log (
          id TEXT PRIMARY KEY,
          surface TEXT NOT NULL,
          called_at TEXT NOT NULL,
          mood_log_id TEXT,
          kept INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trial_milestones (
          milestone TEXT PRIMARY KEY,
          shown_at TEXT
        )
      ''');
    }
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE routines ADD COLUMN voice_enabled INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 15) {
      // templates: add v1.2.0 card revitalization columns
      await db.execute('ALTER TABLE templates ADD COLUMN name_en TEXT');
      await db.execute('ALTER TABLE templates ADD COLUMN layout TEXT NOT NULL DEFAULT \'hero_image\'');
      await db.execute('ALTER TABLE templates ADD COLUMN accent_color TEXT');
      await db.execute('ALTER TABLE templates ADD COLUMN text_area_opacity REAL NOT NULL DEFAULT 0.85');
      await db.execute('ALTER TABLE templates ADD COLUMN text_backdrop_color TEXT');
      await db.execute('ALTER TABLE templates ADD COLUMN footer_text TEXT DEFAULT \'Blinking Notes\'');
      await db.execute('ALTER TABLE templates ADD COLUMN show_mood INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE templates ADD COLUMN show_date INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE templates ADD COLUMN show_tags INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE templates ADD COLUMN show_footer INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE templates ADD COLUMN corner_style TEXT NOT NULL DEFAULT \'rounded\'');
      await db.execute('ALTER TABLE templates ADD COLUMN decoration_style TEXT');

      // note_cards: add v1.2.0 card revitalization columns
      await db.execute('ALTER TABLE note_cards ADD COLUMN card_content TEXT');
      await db.execute('ALTER TABLE note_cards ADD COLUMN emotion TEXT');
      await db.execute('ALTER TABLE note_cards ADD COLUMN display_tags TEXT');
      await db.execute('ALTER TABLE note_cards ADD COLUMN show_mood INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE note_cards ADD COLUMN show_date INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE note_cards ADD COLUMN show_tags INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE note_cards ADD COLUMN show_footer INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE note_cards ADD COLUMN template_overrides TEXT');

      // Replace old 6 templates with new 8 RedNotes-style templates
      await db.delete('templates', where: 'is_built_in = ?', whereArgs: [1]);
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, text_backdrop_color, decoration_style) VALUES "
        "('tpl_ink_rhythm', '墨韵', 'Ink Rhythm', '🖋️', 'default', '#2C2C2C', '#F5F0E8', 1, datetime('now'), 'hero_image', '#C43A31', 0.85, 'rgba(245,240,232,0.85)', 'ink_wash')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, decoration_style) VALUES "
        "('tpl_plain_paper', '素笺', 'Plain Paper', '📃', 'default', '#2C2C2C', '#F5F0E8', 1, datetime('now'), 'left_aligned', '#C43A31', 0.85, 'rice_paper')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, text_backdrop_color, decoration_style) VALUES "
        "('tpl_bamboo', '竹影', 'Bamboo Shadow', '🎋', 'default', '#2C2C2C', '#EDF5EC', 1, datetime('now'), 'hero_image', '#7A9A6D', 0.85, 'rgba(237,245,236,0.85)', 'bamboo')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, text_area_opacity, decoration_style) VALUES "
        "('tpl_moonlight', '月色', 'Moonlight', '🌙', 'default', '#E8E4DF', '#1B2838', 1, datetime('now'), 'centered', 0.80, 'crescent')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, decoration_style) VALUES "
        "('tpl_porcelain', '青花', 'Blue Porcelain', '🏺', 'default', '#2B5F8A', '#FAFAF6', 1, datetime('now'), 'centered', '#2B5F8A', 0.85, 'porcelain')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, text_backdrop_color, decoration_style) VALUES "
        "('tpl_tea', '茶语', 'Tea Whisper', '🍵', 'default', '#5C4033', '#F5EDE3', 1, datetime('now'), 'hero_image', '#D4A76A', 0.85, 'rgba(245,237,227,0.85)', 'tea')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, decoration_style) VALUES "
        "('tpl_seal', '朱砂', 'Cinnabar Seal', '🔴', 'default', '#2C2C2C', '#F5F0E8', 1, datetime('now'), 'centered', '#C43A31', 0.85, 'seal')");
      await db.execute("INSERT INTO templates (id, name, name_en, icon, font_family, font_color, bg_color, is_built_in, created_at, layout, accent_color, text_area_opacity, text_backdrop_color, decoration_style) VALUES "
        "('tpl_landscape', '山水', 'Landscape', '🏔️', 'default', '#2C2C2C', '#D6E0E8', 1, datetime('now'), 'hero_image', '#6B7B8D', 0.85, 'rgba(214,224,232,0.85)', 'landscape')");
    }
    if (oldVersion < 16) {
      await db.execute('ALTER TABLE templates ADD COLUMN background_image_path TEXT');
      await db.execute('ALTER TABLE templates ADD COLUMN text_padding_top REAL NOT NULL DEFAULT 120');
      await db.execute('ALTER TABLE templates ADD COLUMN text_padding_bottom REAL NOT NULL DEFAULT 140');
      await db.execute('ALTER TABLE templates ADD COLUMN text_padding_left REAL NOT NULL DEFAULT 80');
      await db.execute('ALTER TABLE templates ADD COLUMN text_padding_right REAL NOT NULL DEFAULT 80');
      await db.execute('ALTER TABLE templates ADD COLUMN base_font_size REAL NOT NULL DEFAULT 72');
      await db.execute('ALTER TABLE templates ADD COLUMN font_weight_value INTEGER NOT NULL DEFAULT 500');
      await db.execute('ALTER TABLE templates ADD COLUMN text_align_mode TEXT NOT NULL DEFAULT \'center\'');

      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_ink_rhythm.jpg', bg_color='#F2EFE9', text_padding_top=180, text_padding_bottom=180, text_padding_left=140, text_padding_right=140, base_font_size=64, font_weight_value=400, text_align_mode='center', text_backdrop_color=NULL WHERE id='tpl_ink_rhythm' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_plain_paper.jpg', bg_color='#F2EFE9', text_padding_top=120, text_padding_left=160, text_padding_right=160, base_font_size=36, font_weight_value=400, text_align_mode='left' WHERE id='tpl_plain_paper' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_bamboo.jpg', text_padding_top=140, text_padding_bottom=200, text_padding_left=120, text_padding_right=120, base_font_size=60, font_weight_value=500, text_align_mode='center', text_backdrop_color=NULL WHERE id='tpl_bamboo' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_moonlight.jpg', text_padding_top=200, text_padding_left=160, text_padding_right=160, base_font_size=52, font_weight_value=400, text_align_mode='center' WHERE id='tpl_moonlight' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_porcelain.jpg', text_padding_top=120, text_padding_left=160, text_padding_right=160, base_font_size=56, font_weight_value=400, text_align_mode='center' WHERE id='tpl_porcelain' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_tea.jpg', text_padding_top=200, text_padding_left=120, text_padding_right=120, base_font_size=56, font_weight_value=400, text_align_mode='left', text_backdrop_color=NULL WHERE id='tpl_tea' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_seal.jpg', text_padding_top=200, text_padding_left=120, text_padding_right=120, base_font_size=62, font_weight_value=700, text_align_mode='center' WHERE id='tpl_seal' AND is_built_in=1");
      await db.execute("UPDATE templates SET background_image_path='assets/cards/bg_landscape.jpg', text_padding_top=200, text_padding_left=140, text_padding_right=140, base_font_size=54, font_weight_value=500, text_align_mode='center', text_backdrop_color=NULL WHERE id='tpl_landscape' AND is_built_in=1");
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Entries table
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        content TEXT,
        media_json TEXT,
        metadata_json TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        emotion TEXT,
        entry_format TEXT NOT NULL DEFAULT 'note',
        list_items TEXT,
        list_carried_forward INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        color TEXT NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Entry Tags (Many-to-Many)
    await db.execute('''
      CREATE TABLE entry_tags (
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (entry_id, tag_id),
        FOREIGN KEY (entry_id) REFERENCES entries (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');

    // Routines table
    await db.execute('''
      CREATE TABLE routines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        icon TEXT,
        description TEXT,
        description_en TEXT,
        frequency TEXT NOT NULL,
        reminder_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        target_count INTEGER,
        current_count INTEGER DEFAULT 0,
        is_counter INTEGER NOT NULL DEFAULT 0,
        unit TEXT,
        icon_image_path TEXT,
        category TEXT,
        scheduled_days_of_week TEXT,
        scheduled_date TEXT,
        voice_enabled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Completion log table
    await db.execute('''
      CREATE TABLE completions (
        id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        count INTEGER,
        notes TEXT,
        FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE
      )
    ''');

    // Card folders table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS card_folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        name_en TEXT,
        icon TEXT NOT NULL,
        font_family TEXT NOT NULL DEFAULT 'default',
        font_color TEXT NOT NULL DEFAULT '#222222',
        bg_color TEXT NOT NULL DEFAULT '#FFFFFF',
        is_built_in INTEGER NOT NULL DEFAULT 0,
        custom_image_path TEXT,
        source_template_id TEXT,
        created_at TEXT NOT NULL,
        layout TEXT NOT NULL DEFAULT 'hero_image',
        accent_color TEXT,
        text_area_opacity REAL NOT NULL DEFAULT 0.85,
        text_backdrop_color TEXT,
        footer_text TEXT DEFAULT 'Blinking Notes',
        show_mood INTEGER NOT NULL DEFAULT 1,
        show_date INTEGER NOT NULL DEFAULT 1,
        show_tags INTEGER NOT NULL DEFAULT 1,
        show_footer INTEGER NOT NULL DEFAULT 1,
        corner_style TEXT NOT NULL DEFAULT 'rounded',
        decoration_style TEXT,
        background_image_path TEXT,
        text_padding_top REAL NOT NULL DEFAULT 120,
        text_padding_bottom REAL NOT NULL DEFAULT 140,
        text_padding_left REAL NOT NULL DEFAULT 80,
        text_padding_right REAL NOT NULL DEFAULT 80,
        base_font_size REAL NOT NULL DEFAULT 72,
        font_weight_value INTEGER NOT NULL DEFAULT 500,
        text_align_mode TEXT NOT NULL DEFAULT 'center'
      )
    ''');

    // Note cards table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_cards (
        id TEXT PRIMARY KEY,
        template_id TEXT NOT NULL,
        folder_id TEXT NOT NULL,
        rendered_image_path TEXT,
        ai_summary TEXT,
        rich_content TEXT,
        card_content TEXT,
        emotion TEXT,
        display_tags TEXT,
        show_mood INTEGER NOT NULL DEFAULT 1,
        show_date INTEGER NOT NULL DEFAULT 1,
        show_tags INTEGER NOT NULL DEFAULT 1,
        show_footer INTEGER NOT NULL DEFAULT 1,
        template_overrides TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Note card entries (many-to-many)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_card_entries (
        card_id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        PRIMARY KEY (card_id, entry_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_tags_tag_id ON entry_tags(tag_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_completions_routine_id ON completions(routine_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_entry_tags_entry_id ON entry_tags(entry_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_card_entries_card_id ON note_card_entries(card_id)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_identity (
        id INTEGER PRIMARY KEY DEFAULT 1,
        avatar_emoji TEXT NOT NULL DEFAULT '\u2726',
        avatar_image_path TEXT,
        assistant_name TEXT NOT NULL DEFAULT 'Companion',
        personality_string TEXT NOT NULL DEFAULT 'Warm and grounded.',
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lens_sets (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        lens_1 TEXT NOT NULL,
        lens_2 TEXT NOT NULL,
        lens_3 TEXT NOT NULL,
        is_builtin INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_lens_set (
        id INTEGER PRIMARY KEY DEFAULT 1,
        lens_set_id TEXT NOT NULL,
        activated_at TEXT NOT NULL,
        FOREIGN KEY (lens_set_id) REFERENCES lens_sets(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_call_log (
        id TEXT PRIMARY KEY,
        surface TEXT NOT NULL,
        called_at TEXT NOT NULL,
        mood_log_id TEXT,
        kept INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trial_milestones (
        milestone TEXT PRIMARY KEY,
        shown_at TEXT
      )
    ''');
  }

  /// Perform data migration from SharedPreferences to SQLite if needed
  Future<void> migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bool migrated = prefs.getBool('sqlite_migrated') ?? false;
    if (migrated) return;

    final db = await database;

    // Migrate Tags
    final tagsJson = prefs.getString('blinking_tags');
    if (tagsJson != null) {
      final List<dynamic> tagsList = json.decode(tagsJson);
      for (final tagMap in tagsList) {
        final tag = Tag.fromJson(tagMap as Map<String, dynamic>);
        await db.insert('tags', {
          'id': tag.id,
          'name': tag.name,
          'name_en': tag.nameEn,
          'color': tag.color,
          'category': tag.category,
          'created_at': tag.createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }

    // Migrate Routines & Completions
    final routinesJson = prefs.getString('blinking_routines');
    if (routinesJson != null) {
      final List<dynamic> routinesList = json.decode(routinesJson);
      for (final routineMap in routinesList) {
        final routine = Routine.fromJson(routineMap as Map<String, dynamic>);
        await db.insert('routines', {
          'id': routine.id,
          'name': routine.name,
          'name_en': routine.nameEn,
          'icon': routine.icon,
          'description': routine.description,
          'description_en': routine.descriptionEn,
          'frequency': routine.frequency.toString().split('.').last,
          'reminder_time': routine.reminderTime,
          'is_active': routine.isActive ? 1 : 0,
          'target_count': routine.targetCount,
          'current_count': routine.currentCount,
          'is_counter': routine.isCounter ? 1 : 0,
          'unit': routine.unit,
          'created_at': routine.createdAt.toIso8601String(),
          'updated_at': routine.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final completion in routine.completionLog) {
          await db.insert('completions', {
            'id': completion.id,
            'routine_id': routine.id,
            'completed_at': completion.completedAt.toIso8601String(),
            'count': completion.count,
            'notes': completion.notes,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }

    // Migrate Entries & EntryTags
    final entriesJson = prefs.getString('blinking_entries');
    if (entriesJson != null) {
      final List<dynamic> entriesList = json.decode(entriesJson);
      for (final entryMap in entriesList) {
        final entry = Entry.fromJson(entryMap as Map<String, dynamic>);
        await db.insert('entries', {
          'id': entry.id,
          'type': entry.type.toString().split('.').last,
          'content': entry.content,
          'media_json': json.encode(entry.mediaUrls),
          'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
          'created_at': entry.createdAt.toIso8601String(),
          'updated_at': entry.updatedAt.toIso8601String(),
          'emotion': entry.emotion,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final tagId in entry.tagIds) {
          await db.insert('entry_tags', {
            'entry_id': entry.id,
            'tag_id': tagId,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }

    await prefs.setBool('sqlite_migrated', true);
  }

  // ============ HELPER METHODS ============

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    if (_instance._database != null) {
      try {
        await _instance._database!.close();
      } catch (_) {}
      _instance._database = null;
    }
  }

  @visibleForTesting
  static void setTestDatabase(Database db) {
    _instance._database = db;
  }
}

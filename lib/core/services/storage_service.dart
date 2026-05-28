import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import '../../models/entry.dart';
import '../../models/tag.dart';
import '../../models/routine.dart';
import 'database_service.dart';

/// Local storage service using SQLite (via DatabaseService)
/// Preserves legacy SharedPreferences for settings and migration flags.
class StorageService {
  late SharedPreferences _prefs;
  final DatabaseService _dbService = DatabaseService();
  bool _initialized = false;

  /// Initialize storage
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Database
    await _dbService.database;
    
    // Migrate data if first run
    await _dbService.migrateFromSharedPreferences();

    _initialized = true;

    // Initialize default tags if none exist
    final tags = await getTags();
    if (tags.isEmpty) {
      for (final tag in _getDefaultTags()) {
        await addTag(tag);
      }
    } else {
      // Ensure system tags exist for existing users (migration)
      final tagIds = tags.map((t) => t.id).toSet();
      for (final tag in _getSystemTags()) {
        if (!tagIds.contains(tag.id)) {
          await addTag(tag);
        }
      }
    }

    // Initialize default routines if none exist
    final routines = await getRoutines();
    if (routines.isEmpty) {
      for (final routine in _getDefaultRoutines()) {
        await addRoutine(routine);
      }
    }
  }

  /// System tags — always exist, locked from editing/deletion
  List<Tag> _getSystemTags() {
    return [
      Tag(id: 'tag_synthesis', name: 'AI综整', nameEn: 'AI Synthesis', color: '#AF52DE', category: 'system', createdAt: DateTime.now()),
      Tag(id: 'tag_private', name: '私密', nameEn: 'Private', color: '#9E9E9E', category: 'system', createdAt: DateTime.now()),
      Tag(id: 'tag_welcome', name: '欢迎', nameEn: 'Welcome', color: '#34C759', category: 'system', createdAt: DateTime.now()),
    ];
  }

  /// Get default tags (new install)
  List<Tag> _getDefaultTags() {
    return [
      Tag(id: 'tag_family', name: '家人', nameEn: 'Family', color: '#FF9500', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_insight', name: '领悟', nameEn: 'Insight', color: '#5856D6', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_gratitude', name: '感恩', nameEn: 'Gratitude', color: '#FF2D55', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_daily', name: '日常', nameEn: 'Daily', color: '#007AFF', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_wellness', name: '养生', nameEn: 'Wellness', color: '#34C759', category: 'custom', createdAt: DateTime.now()),
      Tag(id: 'tag_learning', name: '学习', nameEn: 'Learning', color: '#AF52DE', category: 'custom', createdAt: DateTime.now()),
      ..._getSystemTags(),
    ];
  }

  /// Get default routines — seeded from routine_setup_file_0513.json
  /// Only 3 are active by default: drink water, read, write a note
  List<Routine> _getDefaultRoutines() {
    // Active: only these 3 nameEn values
    const activeHabits = {'Drink water', 'Read 15 minutes', 'Write a note'};
    
    bool isActiveDefault(String nameEn) => activeHabits.contains(nameEn);
    
    return [
      Routine(id: 'routine_seed_1', name: '喝水', nameEn: 'Drink water', icon: '💧', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '10:00', description: '多数成年人都处于轻度脱水而不自知。影响精力、专注与消化。', descriptionEn: 'Most adults are mildly dehydrated without noticing. Affects energy, focus, digestion.', category: RoutineCategory.health, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_2', name: '维生素 / 服药', nameEn: 'Vitamins / medication', icon: '💊', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '08:00', description: '没有固定时间，依从性容易下降。', descriptionEn: 'Compliance falls off without a consistent time anchor.', category: RoutineCategory.health, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_3', name: '出门走走', nameEn: 'Step outside', icon: '🌤️', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '09:00', description: '清晨的自然光帮助调节睡眠节律，户外时间也能切实地降低压力。', descriptionEn: 'Morning natural light regulates the sleep cycle. Time outdoors measurably lowers stress.', category: RoutineCategory.health, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_4', name: '用牙线', nameEn: 'Floss', icon: '🪥', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '22:00', description: '容易被忽略；长期来看，对牙齿与心血管健康都有好处。', descriptionEn: 'Often skipped; protects long-term dental and cardiovascular health.', category: RoutineCategory.health, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_5', name: '走 5000 步', nameEn: 'Walk 5000 steps', icon: '🚶', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '19:00', description: '每日活动保护心血管与关节；久坐的日子会累积。', descriptionEn: 'Daily movement protects cardiovascular and joint health; sedentary days compound.', category: RoutineCategory.fitness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_6', name: '拉伸 5 分钟', nameEn: 'Stretch 5 minutes', icon: '🧘', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '20:00', description: '维持关节灵活度，化解久坐带来的紧张。', descriptionEn: 'Maintains joint range and releases tension built up from sitting.', category: RoutineCategory.fitness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_7', name: '运动', nameEn: 'Workout', icon: '🏋️', frequency: RoutineFrequency.daily, isActive: false, description: '长期的力量与有氧训练，让身体保持能干的状态。方式自定。', descriptionEn: 'Strength and cardio over time keep the body capable. Pick your own kind.', category: RoutineCategory.fitness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_8', name: '走楼梯', nameEn: 'Take the stairs', icon: '🪜', frequency: RoutineFrequency.daily, isActive: false, description: '日常的小选择，一年下来累积成可观的活动量。', descriptionEn: 'Small daily choices add up to substantial movement over a year.', category: RoutineCategory.fitness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_9', name: '好好吃一餐', nameEn: 'Eat one good meal', icon: '🍽️', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '12:00', description: '多数日子都在匆忙进食。一顿用心的餐，是可以做到的。', descriptionEn: 'Most days slip into eating on the go. One intentional meal is reachable.', category: RoutineCategory.nutrition, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_10', name: '吃蔬菜', nameEn: 'Eat vegetables', icon: '🥬', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '12:00', description: '容易被忽略；却是最有循证依据的饮食习惯。', descriptionEn: 'Easy to skip; the single most evidence-backed dietary habit.', category: RoutineCategory.nutrition, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_11', name: '在家做饭', nameEn: 'Cook at home', icon: '👨‍🍳', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '18:00', description: '做饭既是滋养，也是日常的小小创造。', descriptionEn: 'Cooking is both nourishment and a small daily creative act.', category: RoutineCategory.nutrition, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_12', name: '不省早餐', nameEn: 'Don\'t skip breakfast', icon: '🥐', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '08:00', description: '早餐稳定血糖，定下一天的精力。', descriptionEn: 'Morning food stabilizes blood sugar and sets the day\'s energy.', category: RoutineCategory.nutrition, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_13', name: '11 点前睡觉', nameEn: 'Sleep before 11 PM', icon: '😴', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '22:30', description: '对许多生理系统来说，固定的入睡时间比总时长更重要。', descriptionEn: 'Consistent bedtime matters more than total hours for many systems.', category: RoutineCategory.sleep, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_14', name: '固定时间起床', nameEn: 'Wake at a consistent time', icon: '⏰', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '07:00', description: '每天同一时刻起床，比固定的入睡时间更能稳定生理节律。', descriptionEn: 'Same wake time daily anchors circadian rhythm — even more important than bedtime.', category: RoutineCategory.sleep, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_15', name: '睡前 30 分钟放松', nameEn: 'Wind down 30 minutes before bed', icon: '🌙', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '22:00', description: '一个清晰的过渡，告诉身体该休息了。', descriptionEn: 'A clear transition tells the body it\'s time to sleep.', category: RoutineCategory.sleep, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_16', name: '读书 15 分钟', nameEn: 'Read 15 minutes', icon: '📖', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '21:00', description: '非屏幕的注意力恢复。每天 15 分钟，一生可以累积数百本书。', descriptionEn: 'Non-screen attention recovery. 15 minutes daily compounds into hundreds of books over a life.', category: RoutineCategory.mindfulness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_17', name: '静坐 / 冥想', nameEn: 'Sit quietly / meditate', icon: '🧘', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '07:30', description: '静下来的时刻越来越少。哪怕 5 分钟，也能降低日常的紧张。', descriptionEn: 'Stillness is increasingly rare. Even 5 minutes lowers baseline stress.', category: RoutineCategory.mindfulness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_18', name: '练习', nameEn: 'Practice', icon: '🎯', frequency: RoutineFrequency.daily, isActive: false, description: '日复一日的练习，胜过偶尔的长时间投入。可以是语言、乐器、技艺。', descriptionEn: 'Daily practice beats long sessions for skill acquisition. Pick: language, instrument, craft.', category: RoutineCategory.mindfulness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_19', name: '学一样新的事', nameEn: 'Learn something new', icon: '💡', frequency: RoutineFrequency.daily, isActive: false, description: '每日维持的好奇心，日积月累成为内功。', descriptionEn: 'Curiosity sustained daily becomes mastery over years.', category: RoutineCategory.mindfulness, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_20', name: '写一则笔记', nameEn: 'Write a note', icon: '✍️', frequency: RoutineFrequency.daily, isActive: true, reminderTime: '21:30', description: '笔记本身就是练习。一句话也算。', descriptionEn: 'The journal is the practice. Even a sentence counts.', category: RoutineCategory.reflection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_21', name: '记录心情', nameEn: 'Log mood', icon: '📊', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '21:00', description: '记录心情，建立情绪词汇，时间一长会浮现规律。', descriptionEn: 'Mood awareness builds emotional vocabulary and surfaces patterns over time.', category: RoutineCategory.reflection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_22', name: '写下一件感激的事', nameEn: 'Note one gratitude', icon: '🙏', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '22:00', description: '感恩练习是所有正向心理干预中，研究最一致有效的。', descriptionEn: 'Gratitude practice has the most replicated mental-health evidence of any positive intervention.', category: RoutineCategory.reflection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_23', name: '晚间省思', nameEn: 'Evening reflection', icon: '🌅', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '21:30', description: '一日省思，让所学沉淀，让一天清清楚楚地结束。', descriptionEn: 'Daily review consolidates learning and lets the day close.', category: RoutineCategory.reflection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_24', name: '睡前不看手机', nameEn: 'No phone in bed', icon: '📵', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '22:00', description: '睡前看手机扰乱褪黑素分泌和入睡过程，是回报最大的屏幕习惯。', descriptionEn: 'Phone use before sleep disrupts melatonin and sleep onset. The single highest-leverage screen habit.', category: RoutineCategory.restraint, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_25', name: '中午前不刷社交', nameEn: 'No social media before noon', icon: '🚫', frequency: RoutineFrequency.daily, isActive: false, description: '清晨的输入塑造一天的注意力。守住早晨，回报丰厚。', descriptionEn: 'Morning consumption shapes the day\'s attention. A protected morning is high-leverage.', category: RoutineCategory.restraint, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_26', name: '今日不饮酒', nameEn: 'No alcohol today', icon: '🍺', frequency: RoutineFrequency.daily, isActive: false, description: '即便少量饮酒，也影响睡眠和心情，并长期累积风险。', descriptionEn: 'Even small daily drinking affects sleep, mood, and accumulates risk.', category: RoutineCategory.restraint, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_27', name: '今日不吃甜食', nameEn: 'No sugar today', icon: '🍬', frequency: RoutineFrequency.daily, isActive: false, description: '糖让精力起伏。对多数人来说，先有觉察比绝对戒断更重要。', descriptionEn: 'Sugar destabilizes energy. For most people, awareness matters more than strict elimination.', category: RoutineCategory.restraint, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_28', name: '给家人打电话', nameEn: 'Call family', icon: '📞', frequency: RoutineFrequency.weekly, isActive: false, reminderTime: '16:00', scheduledDaysOfWeek: [7], description: '关系需要维护。许多人后悔没多给家人打电话。', descriptionEn: 'Relationships need maintenance. Many people regret not calling parents more.', category: RoutineCategory.connection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_29', name: '联系一位朋友', nameEn: 'Reach out to a friend', icon: '💬', frequency: RoutineFrequency.weekly, isActive: false, reminderTime: '10:00', scheduledDaysOfWeek: [6], description: '没有刻意的联系，友谊会慢慢淡了。', descriptionEn: 'Friendships drift without intentional contact.', category: RoutineCategory.connection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_30', name: '陪伴爱人', nameEn: 'Quality time with partner', icon: '❤️', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '18:30', description: '日常的用心陪伴，比偶尔的盛大表达更能维持长久的关系。', descriptionEn: 'Daily intentional presence predicts long-term satisfaction more than grand gestures.', category: RoutineCategory.connection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      Routine(id: 'routine_seed_31', name: '专心陪孩子', nameEn: 'Be present with kids', icon: '👶', frequency: RoutineFrequency.daily, isActive: false, reminderTime: '18:00', description: '孩子记住的是陪伴本身，而非具体在做什么。多数父母需要的提醒，是「停下工作」。', descriptionEn: 'Children remember presence more than activities. Most parents need a reminder to stop working.', category: RoutineCategory.connection, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    ];
  }

  // ============ ENTRIES ============

  Future<List<Entry>> getEntries() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('entries', orderBy: 'created_at DESC');
    
    // When querying entries, we also need to join their tags
    final List<Entry> entries = [];
    for (final map in maps) {
      final List<Map<String, dynamic>> tagMaps = await db.query(
        'entry_tags',
        where: 'entry_id = ?',
        whereArgs: [map['id']],
      );
      final tagIds = tagMaps.map((t) => t['tag_id'] as String).toList();
      
      final entryMap = Map<String, dynamic>.from(map);
      entryMap['tagIds'] = tagIds;
      entryMap['type'] = map['type']; // Enum parsing in fromJson handles this
      entryMap['mediaUrls'] = json.decode(map['media_json'] as String);
      entryMap['metadata'] = map['metadata_json'] != null ? json.decode(map['metadata_json'] as String) : null;
      entryMap['createdAt'] = map['created_at'];
      entryMap['updatedAt'] = map['updated_at'];
      entryMap['emotion'] = map['emotion'];
      entryMap['format'] = map['entry_format'];
      entryMap['listItems'] = map['list_items'];
      entryMap['listCarriedForward'] = map['list_carried_forward'] == 1;
      
      entries.add(Entry.fromJson(entryMap));
    }
    return entries;
  }

  Future<void> saveEntries(List<Entry> entries) async {
    // This method is less efficient in SQLite, but kept for legacy support.
    // Better to use addEntry / updateEntry.
    for (final entry in entries) {
      await addEntry(entry);
    }
  }

  Future<void> addEntry(Entry entry) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('entries', {
        'id': entry.id,
        'type': entry.type.toString().split('.').last,
        'content': entry.content,
        'media_json': json.encode(entry.mediaUrls),
        'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
        'emotion': entry.emotion,
        'entry_format': entry.format.name,
        'list_items': ListItem.listToJson(entry.listItems),
        'list_carried_forward': entry.listCarriedForward ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Save tags
      for (final tagId in entry.tagIds) {
        await txn.insert('entry_tags', {
          'entry_id': entry.id,
          'tag_id': tagId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> updateEntry(Entry entry) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update('entries', {
        'type': entry.type.toString().split('.').last,
        'content': entry.content,
        'media_json': json.encode(entry.mediaUrls),
        'metadata_json': entry.metadata != null ? json.encode(entry.metadata) : null,
        'updated_at': entry.updatedAt.toIso8601String(),
        'emotion': entry.emotion,
        'entry_format': entry.format.name,
        'list_items': ListItem.listToJson(entry.listItems),
        'list_carried_forward': entry.listCarriedForward ? 1 : 0,
      }, where: 'id = ?', whereArgs: [entry.id]);

      // Refresh tags
      await txn.delete('entry_tags', where: 'entry_id = ?', whereArgs: [entry.id]);
      for (final tagId in entry.tagIds) {
        await txn.insert('entry_tags', {
          'entry_id': entry.id,
          'tag_id': tagId,
        });
      }
    });
  }

  Future<void> deleteEntry(String id) async {
    final db = await _dbService.database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleListItem(String entryId, String itemId) async {
    final db = await _dbService.database;
    final rows = await db.query('entries', where: 'id = ?', whereArgs: [entryId]);
    if (rows.isEmpty) return;
    final items = ListItem.listFromJson(rows.first['list_items'] as String?);
    final updatedItems = items.map((item) {
      if (item.id == itemId) return item.copyWith(isDone: !item.isDone);
      return item;
    }).toList();
    await db.update(
      'entries',
      {
        'list_items': ListItem.listToJson(updatedItems),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> markListCarriedForward(String entryId) async {
    final db = await _dbService.database;
    await db.update(
      'entries',
      {'list_carried_forward': 1},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  // ============ TAGS ============

  Future<List<Tag>> getTags() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('tags', orderBy: 'name ASC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['createdAt'] = m['created_at'];
      map['nameEn'] = m['name_en'];
      return Tag.fromJson(map);
    }).toList();
  }

  Future<void> saveTags(List<Tag> tags) async {
    for (final tag in tags) {
      await addTag(tag);
    }
  }

  Future<void> addTag(Tag tag) async {
    final db = await _dbService.database;
    await db.insert('tags', {
      'id': tag.id,
      'name': tag.name,
      'name_en': tag.nameEn,
      'color': tag.color,
      'category': tag.category,
      'created_at': tag.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTag(Tag tag) async {
    final db = await _dbService.database;
    await db.update('tags', {
      'name': tag.name,
      'name_en': tag.nameEn,
      'color': tag.color,
      'category': tag.category,
    }, where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteTag(String id) async {
    final db = await _dbService.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ============ ROUTINES ============

  Future<List<Routine>> getRoutines() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('routines', orderBy: 'created_at ASC');
    
    final List<Routine> routines = [];
    for (final map in maps) {
      final List<Map<String, dynamic>> completionMaps = await db.query(
        'completions',
        where: 'routine_id = ?',
        whereArgs: [map['id']],
      );
      
      final routineMap = Map<String, dynamic>.from(map);
      routineMap['isActive'] = map['is_active'] == 1;
      routineMap['isCounter'] = map['is_counter'] == 1;
      routineMap['frequency'] = map['frequency'];
      routineMap['createdAt'] = map['created_at'];
      routineMap['updatedAt'] = map['updated_at'];
      routineMap['nameEn'] = map['name_en'];
      routineMap['description'] = map['description'];
      routineMap['descriptionEn'] = map['description_en'];
      routineMap['reminderTime'] = map['reminder_time'];
      routineMap['targetCount'] = map['target_count'];
      routineMap['currentCount'] = map['current_count'];
      routineMap['category'] = map['category'];
      routineMap['iconImagePath'] = map['icon_image_path'];
      routineMap['voiceEnabled'] = map['voice_enabled'] == 1;
      routineMap['scheduledDaysOfWeek'] = map['scheduled_days_of_week'] != null
          ? (json.decode(map['scheduled_days_of_week'] as String) as List<dynamic>)
              .map((e) => e as int)
              .toList()
          : null;
      routineMap['scheduledDate'] = map['scheduled_date'];
      routineMap['completionLog'] = completionMaps.map((c) => {
        'id': c['id'],
        'routineId': c['routine_id'],
        'completedAt': c['completed_at'],
        'count': c['count'],
        'notes': c['notes'],
      }).toList();
      
      routines.add(Routine.fromJson(routineMap));
    }
    return routines;
  }

  Future<void> saveRoutines(List<Routine> routines) async {
    for (final routine in routines) {
      await addRoutine(routine);
    }
  }

  Future<void> addRoutine(Routine routine) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.insert('routines', {
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
        'icon_image_path': routine.iconImagePath,
        'category': routine.category?.name,
        'scheduled_days_of_week': routine.scheduledDaysOfWeek != null
            ? json.encode(routine.scheduledDaysOfWeek)
            : null,
        'scheduled_date': routine.scheduledDate?.toIso8601String(),
        'voice_enabled': routine.voiceEnabled ? 1 : 0,
        'created_at': routine.createdAt.toIso8601String(),
        'updated_at': routine.updatedAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final completion in routine.completionLog) {
        await txn.insert('completions', {
          'id': completion.id,
          'routine_id': routine.id,
          'completed_at': completion.completedAt.toIso8601String(),
          'count': completion.count,
          'notes': completion.notes,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateRoutine(Routine routine) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update('routines', {
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
        'icon_image_path': routine.iconImagePath,
        'category': routine.category?.name,
        'scheduled_days_of_week': routine.scheduledDaysOfWeek != null
            ? json.encode(routine.scheduledDaysOfWeek)
            : null,
        'scheduled_date': routine.scheduledDate?.toIso8601String(),
        'updated_at': routine.updatedAt.toIso8601String(),
      }, where: 'id = ?', whereArgs: [routine.id]);

      // Refresh completions
      await txn.delete('completions', where: 'routine_id = ?', whereArgs: [routine.id]);
      for (final completion in routine.completionLog) {
        await txn.insert('completions', {
          'id': completion.id,
          'routine_id': routine.id,
          'completed_at': completion.completedAt.toIso8601String(),
          'count': completion.count,
          'notes': completion.notes,
        });
      }
    });
  }

  Future<void> deleteRoutine(String id) async {
    final db = await _dbService.database;
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  // ============ SETTINGS (STILL IN PREFS) ============

  Future<Map<String, dynamic>> getSettings() async {
    final jsonString = _prefs.getString('blinking_settings');
    if (jsonString == null) {
      return {
        'language': 'zh',
        'theme': 'light',
      };
    }
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final jsonString = json.encode(settings);
    await _prefs.setString('blinking_settings', jsonString);
  }

  // ============ SETTINGS ============

  Future<String> getLanguage() async {
    return _prefs.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString('language', language);
  }

  bool getVoiceEnabled() {
    return _prefs.getBool('voice_notifications_enabled') ?? false;
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool('voice_notifications_enabled', enabled);
  }

  Future<String> getTheme() async {
    return _prefs.getString('theme') ?? 'light';
  }

  Future<void> setTheme(String theme) async {
    await _prefs.setString('theme', theme);
  }

  // ============ EXPORT / IMPORT ============

  Future<Map<String, dynamic>> exportData() async {
    final entries = await getEntries();
    final tags = await getTags();
    final routines = await getRoutines();
    final settings = await getSettings();

    return {
      'version': '2.0 (SQLite)',
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'routines': routines.map((r) => r.toJson()).toList(),
      'settings': settings,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (data.containsKey('tags')) {
      final tags = (data['tags'] as List<dynamic>)
          .map((t) => Tag.fromJson(t as Map<String, dynamic>))
          .toList();
      for (final tag in tags) {
        await addTag(tag);
      }
    }

    if (data.containsKey('routines')) {
      final routines = (data['routines'] as List<dynamic>)
          .map((r) => Routine.fromJson(r as Map<String, dynamic>))
          .toList();
      for (final routine in routines) {
        await addRoutine(routine);
      }
    }

    if (data.containsKey('entries')) {
      final entries = (data['entries'] as List<dynamic>)
          .map((e) => Entry.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final entry in entries) {
        await addEntry(entry);
      }
    }

    if (data.containsKey('settings')) {
      await saveSettings(data['settings'] as Map<String, dynamic>);
    }
  }

  /// RESTORE FROM BACKUP (.json or .zip)
  Future<void> restoreFromBackup(
    File backupFile, {
    void Function(double progress)? onProgress,
  }) async {
    final String extension = backupFile.path.split('.').last.toLowerCase();

    if (extension == 'json') {
      final String content = await backupFile.readAsString();
      final Map<String, dynamic> data = json.decode(content);
      await importData(data);
    } else if (extension == 'zip') {
      final inputStream = InputFileStream(backupFile.path);
      Archive? archive;
      try {
        archive = ZipDecoder().decodeStream(inputStream);

        // Phase A: Import data.json with minimal memory
        final dataFile = archive.findFile('data.json');
        if (dataFile != null) {
          final dataBytes = dataFile.content as List<int>;
          final data = json.fuse(utf8).decode(dataBytes) as Map<String, dynamic>;
          await importData(data);
          // Release memory before processing media files
          archive.removeFile(dataFile);
        }

        // Phase B: Stream media & avatar files to disk
        final docDir = await getApplicationDocumentsDirectory();

        // Pre-scan total bytes for byte-weighted progress
        int totalBytes = 0;
        for (final file in archive) {
          if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
            totalBytes += file.size;
          }
        }

        int processedBytes = 0;
        int fileCount = 0;
        for (final file in archive) {
          if (file.isFile && (file.name.startsWith('media/') || file.name.startsWith('avatar/'))) {
            final targetPath = path_pkg.join(docDir.path, file.name);
            final targetDir = Directory(path_pkg.dirname(targetPath));
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }
            final output = OutputFileStream(targetPath);
            try {
              file.writeContent(output);
            } finally {
              await output.close();
            }
            processedBytes += file.size;
            fileCount++;
            if (totalBytes > 0) {
              onProgress?.call(processedBytes / totalBytes);
            }
            // Yield to event loop every 10 files to prevent UI freeze and allow GC
            if (fileCount % 10 == 0) {
              await Future(() {});
            }
          }
        }

        // Phase C: Restore AI persona settings
        final personaFile = archive.findFile('persona.json');
        if (personaFile != null) {
          try {
            final personaMap = json.fuse(utf8).decode(personaFile.content as List<int>) as Map<String, dynamic>;
            if (personaMap.containsKey('ai_assistant_name')) {
              await _prefs.setString('ai_assistant_name', personaMap['ai_assistant_name'] as String);
            }
            if (personaMap.containsKey('ai_assistant_personality')) {
              await _prefs.setString('ai_assistant_personality', personaMap['ai_assistant_personality'] as String);
            }
            if (personaMap.containsKey('ai_avatar_zip_path')) {
              final restoredPath = path_pkg.join(docDir.path, personaMap['ai_avatar_zip_path'] as String);
              await _prefs.setString('ai_avatar_path', restoredPath);
            }
          } catch (_) {
            // persona.json corrupted — skip persona restore, data is already imported
          }
        }
      } finally {
        await archive?.clear();
        await inputStream.close();
      }
    } else {
      throw Exception('Unsupported backup format: $extension');
    }
  }

  Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete('entries');
    await db.delete('tags');
    await db.delete('entry_tags');
    await db.delete('routines');
    await db.delete('completions');
    await _prefs.remove('sqlite_migrated');
  }
}
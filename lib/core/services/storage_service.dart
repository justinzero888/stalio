import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import '../../models/entry.dart';
import '../../models/tag.dart';
import '../../models/tag_category.dart';
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

    // Clean up removed tags
    await deleteTag('tag_synthesis');
    await deleteTag('tag_welcome');

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

    // Initialize default tag categories if none exist
    final categories = await getTagCategories();
    if (categories.isEmpty) {
      for (final cat in _getDefaultCategories()) {
        await addTagCategory(cat);
      }
    }

    // Seed demo entries for validation (disabled — entries should come from habit tracking)
    // final entries = await getEntries();
    // if (entries.isEmpty) {
    //   final seeded = _prefs.getBool('seed_entries_done');
    //   if (seeded != true) {
    //     for (final e in _getSeedEntries()) {
    //       await addEntry(e);
    //     }
    //     await _prefs.setBool('seed_entries_done', true);
    //   }
    // }
  }

  /// System tags — always exist, locked from editing/deletion
  List<Tag> _getSystemTags() {
    return [
      Tag(id: 'tag_private', name: '私密', nameEn: 'Private', color: '#9E9E9E', category: 'system', createdAt: DateTime.now()),
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

  /// Get default routines — from stalio_habits_library_v2.csv (54 habits)
  /// 9 are active by default (isDefaultBundle=true per onboarding design):
  /// H001, H003, H004, H009, H010, H023, H033, H038, H051
  List<Routine> _getDefaultRoutines() {
    final now = DateTime.now();

    // CSV field indices (0-indexed):
    // 0=habit_id, 1=nameEn, 2=nameCn, 3=categoryGroupEn, 4=categoryGroupCn,
    // 5=categoryNameEn, 6=categoryNameCn, 7=trackingUiType, 8=trackingUnit,
    // 9=trackingDefaultTarget, 10=trackingMin, 11=trackingMax, 12=trackingIncrement,
    // 13=timeOfDay, 14=estimatedDurationMin, 15=difficulty, 16=isDefaultBundle,
    // 17=twoMinVersionEn, 18=twoMinVersionCn, 19=customTargetAllowed
    final rows = [
      ['H001','Drink water','喝水','Health & Body','身','Health','养','number','glasses','8','1','20','1','Throughout day','1','easy','TRUE','Drink one full glass of water right now','现在就喝一杯水','TRUE'],
      ['H002','Vitamins / medication','维生素 / 服药','Health & Body','身','Health','养','boolean','yes/no',null,null,null,null,'Morning',null,null,'FALSE','Put your supplements next to something you do every morning','把补充剂放在你每天早上都会做的事情旁边','FALSE'],
      ['H003','Step outside','出门走走','Health & Body','身','Health','养','boolean','yes/no',null,null,null,null,'Any',null,null,'TRUE','Open your front door and stand outside for 30 seconds','打开家门，在外面站 30 秒','FALSE'],
      ['H004','Floss','用牙线','Health & Body','身','Health','养','boolean','yes/no',null,null,null,null,'Evening',null,null,'TRUE','Floss just one gap between two teeth — that\'s a start','只清洁两颗牙之间的缝隙 — 这就是开始','FALSE'],
      ['H005','Walk 5000 steps','走 5000 步','Health & Body','身','Fitness','劲','number','steps','5000','1000','30000','500','Throughout day','20','easy','FALSE','Walk around the block — that\'s about 1,000 steps','绕着街区走一圈 — 大约 1,000 步','TRUE'],
      ['H006','Stretch 5 minutes','拉伸 5 分钟','Health & Body','身','Fitness','劲','duration','minutes','5','1','60','1','Any','5','easy','FALSE','Stand up and do 5 slow neck rolls in each direction','站起来，向每个方向慢慢转动脖子 5 次','TRUE'],
      ['H007','Workout','运动','Health & Body','身','Fitness','劲','boolean_optional_text','yes/no',null,null,null,null,'Any','30','moderate','FALSE','Do 10 bodyweight squats right now','现在做 10 个自重深蹲','FALSE'],
      ['H008','Take the stairs','走楼梯','Health & Body','身','Fitness','劲','boolean','yes/no',null,null,null,null,'Any','2','easy','FALSE','Take the stairs for just one floor today','今天只走一层楼梯','FALSE'],
      ['H009','Eat one good meal','好好吃一餐','Health & Body','身','Nutrition','食','boolean','yes/no',null,null,null,null,'Evening',null,'easy','TRUE','Ask yourself: did I eat one real meal today?','问自己：今天我吃了一顿正经饭吗？','FALSE'],
      ['H010','Eat vegetables','吃蔬菜','Health & Body','身','Nutrition','食','boolean','yes/no',null,null,null,null,'Any',null,'easy','TRUE','Eat one piece of fruit or a handful of raw vegetables right now','现在吃一块水果或一把生蔬菜','FALSE'],
      ['H011','Cook at home','在家做饭','Health & Body','身','Nutrition','食','boolean_optional_text','yes/no',null,null,null,null,'Any','30','moderate','FALSE','Make tomorrow\'s lunch tonight — it takes 5 minutes','今晚做明天的午餐 — 只需 5 分钟','FALSE'],
      ['H012','Don\'t skip breakfast','不省早餐','Health & Body','身','Nutrition','食','boolean','yes/no',null,null,null,null,'Morning','5','easy','FALSE','Eat one bite of anything within the next hour','接下来一小时内吃一口任何东西','FALSE'],
      ['H013','Track calories','记录热量','Health & Body','身','Nutrition','食','number','calories','2000','500','5000','50','Any','5','hard','FALSE','Just log what you eat for breakfast today — nothing else','只记录今天早餐吃了什么 — 其他都不用','TRUE'],
      ['H014','Sleep before 11 PM','11 点前睡觉','Health & Body','心','Sleep','息','time','bedtime',null,null,null,null,'Evening',null,'easy','FALSE','Go to bed 15 minutes earlier than last night','比昨晚早睡 15 分钟','FALSE'],
      ['H015','Wake at consistent time','固定时间起床','Health & Body','心','Sleep','息','time','wake_time',null,null,null,null,'Morning',null,'easy','FALSE','Set your alarm for the same time tomorrow — even weekend','把明天的闹钟设在同一个时间 — 即使是周末','FALSE'],
      ['H016','Wind down 30 min before bed','睡前 30 分钟放松','Health & Body','心','Sleep','息','boolean','yes/no',null,null,null,null,'Evening','30','moderate','FALSE','Dim every light in your home right now','现在把家里所有的灯调暗','FALSE'],
      ['H017','Sleep quality log','记录睡眠质量','Health & Body','心','Sleep','息','scale','1-5 rating',null,'1','5','1','Morning',null,'easy','FALSE','Rate last night\'s sleep from 1 to 5 right now','现在给昨晚的睡眠评分 1 到 5','FALSE'],
      ['H018','Read 15 minutes','读书 15 分钟','Health & Body','心','Mind','心','duration','minutes','15','5','120','5','Evening','15','moderate','FALSE','Read the next page of whatever book is nearest you','读离你最近的书下一页','TRUE'],
      ['H019','Sit quietly / meditate','静坐 / 冥想','Health & Body','心','Mind','心','duration','minutes','5','1','60','1','Morning','8','moderate','FALSE','Sit still for 2 minutes and count your breaths','静坐 2 分钟，数呼吸','FALSE'],
      ['H020','Practice gratitude','练习感恩','Health & Body','心','Mind','心','multi_text_required','items','3','1','10','1','Evening','3','easy','FALSE','Name one thing that went well today','说出今天顺利的一件事','FALSE'],
      ['H021','Learn something new','学一样新的事','Health & Body','心','Mind','心','text_required','text',null,null,null,null,'Evening','2','easy','FALSE','Ask someone: \'What\'s one thing you learned recently?\'','问别人：\'你最近学到的一件事是什么？\'','FALSE'],
      ['H022','Zen garden coloring','禅意涂色','Health & Body','心','Mind','心','duration','minutes','15','5','60','5','Evening','15','moderate','FALSE','Doodle on a piece of paper for 2 minutes','在一张纸上涂鸦 2 分钟','TRUE'],
      ['H023','Write a note','写一则笔记','Health & Body','心','Reflection','省','text_required','text',null,null,null,null,'Any','3','easy','TRUE','Write one sentence about how you feel right now','写一句话描述你现在的感受','FALSE'],
      ['H024','Log mood','记录心情','Health & Body','心','Reflection','省','scale_optional_text','1-5 rating',null,'1','5','1','Evening',null,'easy','FALSE','Rate your day from 1 to 5 right now','现在给你的一天评分 1 到 5','FALSE'],
      ['H025','Note one gratitude','写下一件感激的事','Health & Body','心','Reflection','省','text_required','text',null,null,null,null,'Evening',null,'easy','FALSE','Think of one thing that went well today — that\'s it','想一件今天顺利的事 — 就这样','FALSE'],
      ['H026','Evening reflection','晚间省思','Health & Body','心','Reflection','省','text_required','text',null,null,null,null,'Evening','5','easy','FALSE','Write down one thing you learned about yourself today','写下你今天了解到的关于自己的一件事','FALSE'],
      ['H027','Call family','给家人打电话','Social & Relationship','缘','Connection','缘','boolean_optional_text','yes/no',null,null,null,null,'Any','10','easy','FALSE','Call one family member for just 2 minutes','给一位家人打电话，只说 2 分钟','FALSE'],
      ['H028','Reach out to a friend','联系一位朋友','Social & Relationship','缘','Connection','缘','boolean_optional_text','yes/no',null,null,null,null,'Any','5','easy','FALSE','Text one person right now who you haven\'t spoken to this week','现在就给本周没说过话的人发条消息','FALSE'],
      ['H029','Quality time with partner','陪伴爱人','Social & Relationship','缘','Connection','缘','duration_optional_text','minutes','15','5','120','5','Evening','15','easy','FALSE','Put phones away and talk to your partner for 5 minutes','把手机收起来，和伴侣交谈 5 分钟','TRUE'],
      ['H030','Be present with kids','专心陪孩子','Social & Relationship','缘','Connection','缘','duration_optional_text','minutes','15','5','60','5','Evening','15','easy','FALSE','Put your phone in another room and ask your child about their day','把手机放在另一个房间，问你的孩子今天过得怎么样','TRUE'],
      ['H031','Device-free family time','无电子设备的家庭时光','Social & Relationship','缘','Connection','缘','duration_optional_text','minutes','30','15','180','15','Evening','30','moderate','FALSE','Put every phone in the house in another room for 30 minutes','把家里所有手机放在另一个房间 30 分钟','TRUE'],
      ['H032','Act of kindness','做一件善事','Social & Relationship','缘','Connection','缘','boolean_optional_text','yes/no',null,null,null,null,'Any','5','easy','FALSE','Send one genuine compliment to someone right now','现在就给某人发一句真诚的赞美','FALSE'],
      ['H033','No phone in bed','睡前不看手机','Social & Relationship','缘','Restraint','戒','boolean','yes/no',null,null,null,null,'Evening',null,'easy','TRUE','Charge your phone on the other side of the room tonight','今晚把手机放在房间另一头充电','FALSE'],
      ['H034','No social media before noon','中午前不刷社交','Social & Relationship','缘','Restraint','戒','boolean','yes/no',null,null,null,null,'Morning',null,'moderate','FALSE','Delete social apps from your home screen — put them in a folder','把社交应用从主屏幕删除 — 放进一个文件夹','FALSE'],
      ['H035','No alcohol today','今日不饮酒','Social & Relationship','缘','Restraint','戒','boolean','yes/no',null,null,null,null,'Evening',null,'moderate','FALSE','Pour a non-alcoholic drink tonight instead','今晚倒一杯无酒精饮料代替','FALSE'],
      ['H036','No sugar today','今日不吃甜食','Social & Relationship','缘','Restraint','戒','boolean','yes/no',null,null,null,null,'Any',null,'moderate','FALSE','Skip one sugary thing you usually have today','今天跳过你通常吃的某样含糖食物','FALSE'],
      ['H037','No smoking today','今日不吸烟','Social & Relationship','缘','Restraint','戒','streak','days',null,null,null,null,'Any',null,'hard','FALSE','Don\'t have one cigarette today — just today','今天不抽一支烟 — 就今天','FALSE'],
      ['H038','No-spend day','今日不花钱','Social & Relationship','缘','Restraint','戒','boolean','yes/no',null,null,null,null,'Any',null,'moderate','TRUE','Decide right now: will today be a no-spend day?','现在决定：今天要不要不花钱？','FALSE'],
      ['H039','Screen time limit','限制屏幕时间','Social & Relationship','缘','Restraint','戒','number','minutes','120','15','480','15','Any',null,'moderate','FALSE','Set a 30-minute timer before opening any social app tonight','今晚打开任何社交应用前设置一个 30 分钟计时器','TRUE'],
      ['H040','Language practice','语言练习','Productivity & Growth','长','Growth','长','duration_optional_text','minutes','15','5','60','5','Morning','15','moderate','FALSE','Open Duolingo and complete one lesson right now','打开 Duolingo 完成一课','TRUE'],
      ['H041','Skill study','技能学习','Productivity & Growth','长','Growth','长','duration_optional_text','minutes','30','15','120','15','Any','30','moderate','FALSE','Open your course and do 5 minutes — just 5','打开你的课程做 5 分钟 — 就 5 分钟','TRUE'],
      ['H042','Review top 3 priorities','回顾 3 件要事','Productivity & Growth','长','Growth','长','multi_text_required','text',null,null,null,null,'Morning','5','easy','FALSE','Write down the one most important thing for today','写下今天最重要的一件事','FALSE'],
      ['H043','Creative work','创意工作','Productivity & Growth','长','Growth','长','duration_optional_text','minutes','30','10','120','10','Any','30','moderate','FALSE','Make one small thing right now — even a rough draft','现在做一件小事 — 即使是草稿','TRUE'],
      ['H044','Learning log','学习日志','Productivity & Growth','长','Growth','长','text_required','text',null,null,null,null,'Evening','2','easy','FALSE','Write one sentence: what\'s one thing I noticed or learned today?','写一句话：我今天注意到或学到的一件事是什么？','FALSE'],
      ['H045','Deep work block','深度工作','Productivity & Growth','长','Growth','长','duration_optional_text','minutes','120','25','240','25','Morning','120','hard','FALSE','Close all browser tabs except one and work for 25 minutes','关闭除一个之外的所有浏览器标签，工作 25 分钟','TRUE'],
      ['H046','Log spending','记录支出','Financial','财','Financial','财','multi_text_required','text',null,null,null,null,'Evening','5','moderate','FALSE','Log the last thing you spent money on','记录你最后花钱买的东西','FALSE'],
      ['H047','Transfer to savings','转存储蓄','Financial','财','Financial','财','number','amount (\u0024)',null,null,null,null,'Morning','2','easy','FALSE',r'Transfer $1 to savings right now — seriously, just $1','现在转账 1 美元到储蓄 — 认真的，就 1 美元','TRUE'],
      ['H048','Weekly budget review','每周预算回顾','Financial','财','Financial','财','text_required','text',null,null,null,null,'Any','15','moderate','FALSE','Open your bank app and look at this week\'s spending right now','打开你的银行应用看看这周的支出','FALSE'],
      ['H049','Invest today','今日投资','Financial','财','Financial','财','boolean_optional_text','yes/no',null,null,null,null,'Any','5','moderate','FALSE','Open your investment app and look at your account balance','打开你的投资应用看看账户余额','FALSE'],
      ['H050','Credit score check','检查信用评分','Financial','财','Financial','财','boolean_optional_text','yes/no',null,null,null,null,'Any','5','easy','FALSE','Check your credit score right now — most banks show it for free','现在查看你的信用评分 — 大多数银行免费提供','FALSE'],
      ['H051','Make the bed','整理床铺','Home & Environment','居','Environment','居','boolean','yes/no',null,null,null,null,'Morning','3','easy','TRUE','Pull up your duvet right now — that counts','现在拉平你的被子 — 这就算','FALSE'],
      ['H052','Tidy for 10 min','打扫 10 分钟','Home & Environment','居','Environment','居','duration','minutes','10','5','30','5','Evening','10','easy','FALSE','Set a 10-minute timer and just start — anywhere','设置一个 10 分钟的计时器，随便从哪里开始','FALSE'],
      ['H053','Declutter one thing','断舍离一件物品','Home & Environment','居','Environment','居','boolean_optional_text','yes/no',null,null,null,null,'Any','5','easy','FALSE','Pick up the first thing you see that you don\'t need — let it go','拿起你看到的第一件不需要的东西 — 让它走','FALSE'],
      ['H054','Gardening','园艺','Home & Environment','居','Environment','居','duration_optional_text','minutes','10','5','60','5','Any','10','easy','FALSE','Water one plant right now','现在给一株植物浇水','TRUE'],
    ];

    // Emoji icons mapping
    const icons = {
      'H001': '💧', 'H002': '💊', 'H003': '🌿', 'H004': '🪥',
      'H005': '🚶', 'H006': '🧘', 'H007': '🏋️', 'H008': '🪜',
      'H009': '🍽️', 'H010': '🥗', 'H011': '👨‍🍳', 'H012': '🥐',
      'H013': '🔢', 'H014': '😴', 'H015': '⏰', 'H016': '🌙',
      'H017': '💤', 'H018': '📖', 'H019': '🧘', 'H020': '🙏',
      'H021': '📚', 'H022': '🎨', 'H023': '✏️', 'H024': '😊',
      'H025': '🙏', 'H026': '🌅', 'H027': '📞', 'H028': '💬',
      'H029': '❤️', 'H030': '👶', 'H031': '📵', 'H032': '💝',
      'H033': '📵', 'H034': '🚫', 'H035': '🍺', 'H036': '🍬',
      'H037': '🚭', 'H038': '💰', 'H039': '📱', 'H040': '🗣️',
      'H041': '📚', 'H042': '🎯', 'H043': '🎨', 'H044': '📝',
      'H045': '🧠', 'H046': '💳', 'H047': '🏦', 'H048': '📊',
      'H049': '📈', 'H050': '🏦', 'H051': '🛏️', 'H052': '🧹',
      'H053': '📦', 'H054': '🌱',
    };

    return rows.map((r) {
      final category = parseCsvCategory(r[5] as String?);
      final trackingUiType = parseTrackingUiType(r[7] as String?);
      final isDefaultBundle = parseCsvBool(r[16] as String?);
      return Routine(
        id: 'seed_${r[0]}',
        name: r[2] as String,
        nameEn: r[1] as String,
        icon: icons[r[0]] ?? '⭐',
        frequency: RoutineFrequency.daily,
        isActive: isDefaultBundle,
        category: category,
        trackingUiType: trackingUiType,
        categoryGroup: r[3] as String?,
        trackingTarget: parseCsvDouble(r[9] as String?),
        trackingMin: parseCsvDouble(r[10] as String?),
        trackingMax: parseCsvDouble(r[11] as String?),
        trackingIncrement: parseCsvDouble(r[12] as String?),
        trackingUnit: r[8] as String?,
        timeOfDay: (r[13] as String?),
        difficulty: (r[15] as String?),
        estimatedDuration: parseCsvInt(r[14] as String?),
        isDefaultBundle: isDefaultBundle,
        customTargetAllowed: parseCsvBool(r[19] as String?),
        twoMinVersionEn: r[17] as String?,
        twoMinVersionCn: r[18] as String?,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  List<TagCategory> _getDefaultCategories() {
    final now = DateTime.now();
    return [
      TagCategory(id: 'cat_health', name: '养', nameEn: 'Health', color: '#34C759', icon: '💊', sortOrder: 0, createdAt: now),
      TagCategory(id: 'cat_fitness', name: '劲', nameEn: 'Fitness', color: '#FF9500', icon: '🏃', sortOrder: 1, createdAt: now),
      TagCategory(id: 'cat_nutrition', name: '食', nameEn: 'Nutrition', color: '#FF3B30', icon: '🥗', sortOrder: 2, createdAt: now),
      TagCategory(id: 'cat_sleep', name: '息', nameEn: 'Sleep', color: '#5856D6', icon: '😴', sortOrder: 3, createdAt: now),
      TagCategory(id: 'cat_mind', name: '心', nameEn: 'Mind', color: '#AF52DE', icon: '🧘', sortOrder: 4, createdAt: now),
      TagCategory(id: 'cat_reflection', name: '省', nameEn: 'Reflection', color: '#007AFF', icon: '💭', sortOrder: 5, createdAt: now),
      TagCategory(id: 'cat_restraint', name: '戒', nameEn: 'Restraint', color: '#FF2D55', icon: '🛡️', sortOrder: 6, createdAt: now),
      TagCategory(id: 'cat_connection', name: '缘', nameEn: 'Connection', color: '#FF6B35', icon: '👥', sortOrder: 7, createdAt: now),
      TagCategory(id: 'cat_growth', name: '长', nameEn: 'Growth', color: '#64D2FF', icon: '🌱', sortOrder: 8, createdAt: now),
      TagCategory(id: 'cat_financial', name: '财', nameEn: 'Financial', color: '#30D158', icon: '💰', sortOrder: 9, createdAt: now),
      TagCategory(id: 'cat_environment', name: '居', nameEn: 'Environment', color: '#FFD60A', icon: '🏠', sortOrder: 10, createdAt: now),
      TagCategory(id: 'cat_other', name: '杂', nameEn: 'Other', color: '#9E9E9E', icon: '⭐', sortOrder: 11, createdAt: now),
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
      map['categoryId'] = m['category_id'];
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
      'category_id': tag.categoryId,
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
      'category_id': tag.categoryId,
    }, where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> deleteTag(String id) async {
    final db = await _dbService.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reassignEntryTags(String fromTagId, String toTagId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      final rows = await txn.query('entry_tags', where: 'tag_id = ?', whereArgs: [fromTagId]);
      for (final row in rows) {
        final entryId = row['entry_id'] as String;
        final existing = await txn.query('entry_tags',
            where: 'entry_id = ? AND tag_id = ?', whereArgs: [entryId, toTagId]);
        if (existing.isEmpty) {
          await txn.insert('entry_tags', {
            'entry_id': entryId,
            'tag_id': toTagId,
          });
        }
      }
      await txn.delete('entry_tags', where: 'tag_id = ?', whereArgs: [fromTagId]);
    });
  }

  Future<void> deleteTagsByIds(List<String> ids) async {
    final db = await _dbService.database;
    for (final id in ids) {
      await db.delete('tags', where: 'id = ?', whereArgs: [id]);
    }
  }

  // ============ TAG CATEGORIES ============

  Future<List<TagCategory>> getTagCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('tag_categories', orderBy: 'sort_order ASC, name ASC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['nameEn'] = m['name_en'];
      map['sortOrder'] = m['sort_order'];
      map['createdAt'] = m['created_at'];
      return TagCategory.fromJson(map);
    }).toList();
  }

  Future<void> addTagCategory(TagCategory category) async {
    final db = await _dbService.database;
    await db.insert('tag_categories', {
      'id': category.id,
      'name': category.name,
      'name_en': category.nameEn,
      'color': category.color,
      'icon': category.icon,
      'sort_order': category.sortOrder,
      'created_at': category.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTagCategory(TagCategory category) async {
    final db = await _dbService.database;
    await db.update('tag_categories', {
      'name': category.name,
      'name_en': category.nameEn,
      'color': category.color,
      'icon': category.icon,
      'sort_order': category.sortOrder,
    }, where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteTagCategory(String id) async {
    final db = await _dbService.database;
    await db.delete('tag_categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTagCategoryUsageCount(String categoryId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tags WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Tag>> getTagsByCategoryId(String categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tags',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['createdAt'] = m['created_at'];
      map['nameEn'] = m['name_en'];
      map['categoryId'] = m['category_id'];
      return Tag.fromJson(map);
    }).toList();
  }

  Future<void> reorderTagCategories(List<TagCategory> categories) async {
    final db = await _dbService.database;
    final batch = db.batch();
    for (int i = 0; i < categories.length; i++) {
      batch.update('tag_categories', {'sort_order': i}, where: 'id = ?', whereArgs: [categories[i].id]);
    }
    await batch.commit(noResult: true);
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
      routineMap['trackingUiType'] = map['tracking_ui_type'] ?? 'boolean';
      routineMap['categoryGroup'] = map['category_group'];
      routineMap['trackingTarget'] = map['tracking_target'];
      routineMap['trackingMin'] = map['tracking_min'];
      routineMap['trackingMax'] = map['tracking_max'];
      routineMap['trackingIncrement'] = map['tracking_increment'];
      routineMap['trackingUnit'] = map['tracking_unit'];
      routineMap['timeOfDay'] = map['time_of_day'];
      routineMap['difficulty'] = map['difficulty'];
      routineMap['estimatedDuration'] = map['estimated_duration'];
      routineMap['isDefaultBundle'] = map['is_default_bundle'] == 1;
      routineMap['customTargetAllowed'] = map['custom_target_allowed'] == null ? true : map['custom_target_allowed'] == 1;
      routineMap['twoMinVersionEn'] = map['two_min_version_en'];
      routineMap['twoMinVersionCn'] = map['two_min_version_cn'];
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
        'tracking_ui_type': routine.trackingUiType.name,
        'category_group': routine.categoryGroup,
        'tracking_target': routine.trackingTarget,
        'tracking_min': routine.trackingMin,
        'tracking_max': routine.trackingMax,
        'tracking_increment': routine.trackingIncrement,
        'tracking_unit': routine.trackingUnit,
        'time_of_day': routine.timeOfDay,
        'difficulty': routine.difficulty,
        'estimated_duration': routine.estimatedDuration,
        'is_default_bundle': routine.isDefaultBundle ? 1 : 0,
        'custom_target_allowed': routine.customTargetAllowed ? 1 : 0,
        'two_min_version_en': routine.twoMinVersionEn,
        'two_min_version_cn': routine.twoMinVersionCn,
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
        'voice_enabled': routine.voiceEnabled ? 1 : 0,
        'tracking_ui_type': routine.trackingUiType.name,
        'category_group': routine.categoryGroup,
        'tracking_target': routine.trackingTarget,
        'tracking_min': routine.trackingMin,
        'tracking_max': routine.trackingMax,
        'tracking_increment': routine.trackingIncrement,
        'tracking_unit': routine.trackingUnit,
        'time_of_day': routine.timeOfDay,
        'difficulty': routine.difficulty,
        'estimated_duration': routine.estimatedDuration,
        'is_default_bundle': routine.isDefaultBundle ? 1 : 0,
        'custom_target_allowed': routine.customTargetAllowed ? 1 : 0,
        'two_min_version_en': routine.twoMinVersionEn,
        'two_min_version_cn': routine.twoMinVersionCn,
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

  // ============ ONBOARDING ============

  bool isOnboardingComplete() {
    return _prefs.getBool('onboarding_complete') ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _prefs.setBool('onboarding_complete', complete);
  }

  // ============ TOOLTIPS ============

  bool isTooltipSeen(String key) {
    return _prefs.getBool('tooltip_$key') ?? false;
  }

  Future<void> setTooltipSeen(String key) async {
    await _prefs.setBool('tooltip_$key', true);
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
      try { await clearAll(); } catch (_) {}
      final String content = await backupFile.readAsString();
      final Map<String, dynamic> data = json.decode(content);
      await importData(data);
      try { await _ensureDefaultCategories(); } catch (_) {}
    } else if (extension == 'zip') {
      try { await clearAll(); } catch (_) {}
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

        try { await _ensureDefaultCategories(); } catch (_) {}

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

  /// Re-seed tag categories after a restore if the table is empty
  Future<void> _ensureDefaultCategories() async {
    final categories = await getTagCategories();
    if (categories.isEmpty) {
      for (final cat in _getDefaultCategories()) {
        await addTagCategory(cat);
      }
    }
  }

  Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete('entries');
    await db.delete('tags');
    await db.delete('entry_tags');
    await db.delete('routines');
    await db.delete('completions');
    await db.delete('tag_categories');
    await _prefs.remove('sqlite_migrated');
    await _prefs.remove('seed_entries_done');
    await _prefs.remove('onboarding_complete');
  }

  /// Seed entries with tags and emotions for demo/validation
  List<Entry> _getSeedEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      Entry(id: 'seed_entry_1', type: EntryType.freeform,
        content: 'Sunshine and a perfect breeze — took a long walk by the river today.',
        tagIds: ['tag_daily', 'tag_gratitude'], emotion: '😊',
        createdAt: today, updatedAt: today),
      Entry(id: 'seed_entry_2', type: EntryType.freeform,
        content: 'Grateful for morning coffee and a chance encounter with an old friend. Warm moments in ordinary days.',
        tagIds: ['tag_family', 'tag_gratitude'], emotion: '🥰',
        createdAt: today.subtract(const Duration(days: 1)), updatedAt: today.subtract(const Duration(days: 1))),
      Entry(id: 'seed_entry_3', type: EntryType.freeform,
        content: 'Each small step taken in the right direction brings us closer to where we need to be. Progress over perfection.',
        tagIds: ['tag_insight', 'tag_learning'], emotion: '😌',
        createdAt: today.subtract(const Duration(days: 1)), updatedAt: today.subtract(const Duration(days: 1))),
      Entry(id: 'seed_entry_4', type: EntryType.freeform,
        content: 'Stillness.',
        tagIds: ['tag_insight'], emotion: '😐',
        createdAt: today.subtract(const Duration(days: 2)), updatedAt: today.subtract(const Duration(days: 2))),
      Entry(id: 'seed_entry_5', type: EntryType.freeform,
        content: 'Life is like tea — first steep is bitter, second is sweet like love, third mellows into calm clarity. Maybe the secret is simply this: find peace within the noise.',
        tagIds: ['tag_insight', 'tag_wellness'], emotion: '😌',
        createdAt: today.subtract(const Duration(days: 2)), updatedAt: today.subtract(const Duration(days: 2))),
      Entry(id: 'seed_entry_6', type: EntryType.freeform,
        content: 'Morning run felt incredible. The park was quiet at 6am, just a few birds singing. Five kilometers, drenched in sweat, but the clarity afterwards is unmatched.',
        tagIds: ['tag_daily', 'tag_wellness'], emotion: '😊',
        createdAt: today.subtract(const Duration(days: 3)), updatedAt: today.subtract(const Duration(days: 3))),
      Entry(id: 'seed_entry_7', type: EntryType.freeform,
        content: 'The rain tapped softly against the window. There\'s something beautiful about melancholy — it sharpens memory and makes the ordinary feel profound.',
        tagIds: ['tag_insight', 'tag_learning'], emotion: '😢',
        createdAt: today.subtract(const Duration(days: 3)), updatedAt: today.subtract(const Duration(days: 3))),
      Entry(id: 'seed_entry_8', type: EntryType.freeform,
        content: 'Work has been overwhelming. Back-to-back meetings and endless emails. Need to pause and breathe. Tomorrow is another chance to reset.',
        tagIds: ['tag_learning'], emotion: '😤',
        createdAt: today.subtract(const Duration(days: 4)), updatedAt: today.subtract(const Duration(days: 4))),
    ];
  }
}
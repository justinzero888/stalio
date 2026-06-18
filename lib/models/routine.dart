/// Routine frequency enum
enum RoutineFrequency {
  daily,
  weekly,
  scheduled,  // one-time on scheduledDate
  adhoc,      // never auto-appears; manual per-day inclusion
}

/// Routine category enum — drives the default icon shown on the routine tile
enum RoutineCategory {
  health,
  fitness,
  nutrition,
  sleep,
  mind,
  reflection,
  restraint,
  connection,
  growth,
  financial,
  environment,
  other,
}

/// Tracking UI type — determines which popup dialog is shown when tapping a habit
enum TrackingUiType {
  boolean,
  booleanOptionalText,
  duration,
  durationOptionalText,
  number,
  time,
  scale,
  scaleOptionalText,
  textRequired,
  multiTextRequired,
  streak,
}

/// Map category → icon asset path
const Map<RoutineCategory, String> kCategoryIconPath = {
  RoutineCategory.health: 'assets/icons/health.png',
  RoutineCategory.fitness: 'assets/icons/fitness.png',
  RoutineCategory.nutrition: 'assets/icons/nutrition.png',
  RoutineCategory.sleep: 'assets/icons/sleep.png',
  RoutineCategory.mind: 'assets/icons/mind.png',
  RoutineCategory.reflection: 'assets/icons/reflection.png',
  RoutineCategory.restraint: 'assets/icons/restraint.png',
  RoutineCategory.connection: 'assets/icons/connection.png',
  RoutineCategory.growth: 'assets/icons/growth.png',
  RoutineCategory.financial: 'assets/icons/financial.png',
  RoutineCategory.environment: 'assets/icons/environment.png',
  RoutineCategory.other: 'assets/icons/other.png',
};

/// Emoji fallback per category (used when icon path is unavailable)
const Map<RoutineCategory, String> kCategoryEmoji = {
  RoutineCategory.health: '💊',
  RoutineCategory.fitness: '🏃',
  RoutineCategory.nutrition: '🥗',
  RoutineCategory.sleep: '😴',
  RoutineCategory.mind: '🧘',
  RoutineCategory.reflection: '💭',
  RoutineCategory.restraint: '🛡️',
  RoutineCategory.connection: '👥',
  RoutineCategory.growth: '🌱',
  RoutineCategory.financial: '💰',
  RoutineCategory.environment: '🏠',
  RoutineCategory.other: '⭐',
};

/// Localized category names
String routineCategoryName(RoutineCategory cat, bool isZh) {
  switch (cat) {
    case RoutineCategory.health: return isZh ? '养' : 'Health';
    case RoutineCategory.fitness: return isZh ? '劲' : 'Fitness';
    case RoutineCategory.nutrition: return isZh ? '食' : 'Nutrition';
    case RoutineCategory.sleep: return isZh ? '息' : 'Sleep';
    case RoutineCategory.mind: return isZh ? '心' : 'Mind';
    case RoutineCategory.reflection: return isZh ? '省' : 'Reflection';
    case RoutineCategory.restraint: return isZh ? '戒' : 'Restraint';
    case RoutineCategory.connection: return isZh ? '缘' : 'Connection';
    case RoutineCategory.growth: return isZh ? '长' : 'Growth';
    case RoutineCategory.financial: return isZh ? '财' : 'Financial';
    case RoutineCategory.environment: return isZh ? '居' : 'Environment';
    case RoutineCategory.other: return isZh ? '杂' : 'Other';
  }
}

/// Keyword → category mapping for auto-detection
const Map<RoutineCategory, List<String>> kCategoryKeywords = {
  RoutineCategory.health: ['维生素', 'vitamin', '药', 'medicine', '健康', 'health', '医', '早起', 'wake'],
  RoutineCategory.fitness: ['步', 'steps', '运动', 'exercise', '跑', 'run', '健身', 'gym', '瑜伽', 'yoga', '走路', 'walk', '拉伸', 'stretch'],
  RoutineCategory.nutrition: ['喝水', 'water', '饮食', 'diet', '营养', 'nutrition', '蔬菜', 'vegetable', '水果', 'fruit', '吃菜', 'greens'],
  RoutineCategory.sleep: ['睡眠', 'sleep', '睡觉', '休息', 'rest', '早睡', '起床', 'wake'],
  RoutineCategory.mind: ['冥想', 'meditation', '呼吸', 'breath', '正念', 'mindful', '阅读', 'read', '书', 'book'],
  RoutineCategory.reflection: ['感恩', 'gratitude', '日记', 'journal', '反思', 'reflect', '写作', 'write'],
  RoutineCategory.restraint: ['戒', 'quit', '戒烟', '戒酒', '戒糖', '克制', 'restrain', '戒除', '不吃'],
  RoutineCategory.connection: ['朋友', 'friend', '家人', 'family', '聊天', 'chat', '社交', 'social', '电话', 'call', '联络', 'connect'],
  RoutineCategory.growth: ['学习', 'learn', '技能', 'skill', '语言', 'language', '创意', 'creative', '工作', 'work'],
  RoutineCategory.financial: ['钱', 'money', '支出', 'spend', '储蓄', 'saving', '预算', 'budget', '投资', 'invest'],
  RoutineCategory.environment: ['打扫', 'clean', '整理', 'tidy', '床', 'bed', '园艺', 'garden', '植物', 'plant'],
};

/// Auto-detect category from routine name.
/// Returns null if no keyword matches (caller falls back to stored icon or '⭐').
RoutineCategory? autoDetectCategory(String name) {
  final lower = name.toLowerCase();
  for (final entry in kCategoryKeywords.entries) {
    for (final kw in entry.value) {
      if (lower.contains(kw.toLowerCase())) {
        return entry.key;
      }
    }
  }
  return null;
}

/// Parse CSV category_name_en string to RoutineCategory enum
RoutineCategory? parseCsvCategory(String? categoryName) {
  if (categoryName == null) return null;
  switch (categoryName.toLowerCase()) {
    case 'health': return RoutineCategory.health;
    case 'fitness': return RoutineCategory.fitness;
    case 'nutrition': return RoutineCategory.nutrition;
    case 'sleep': return RoutineCategory.sleep;
    case 'mind': return RoutineCategory.mind;
    case 'reflection': return RoutineCategory.reflection;
    case 'restraint': return RoutineCategory.restraint;
    case 'connection': return RoutineCategory.connection;
    case 'growth': return RoutineCategory.growth;
    case 'financial': return RoutineCategory.financial;
    case 'environment': return RoutineCategory.environment;
    default: return RoutineCategory.other;
  }
}

/// Parse CSV tracking_ui_type string to TrackingUiType enum
TrackingUiType parseTrackingUiType(String? typeStr) {
  if (typeStr == null) return TrackingUiType.boolean;
  switch (typeStr.toLowerCase().replaceAll('_', '')) {
    case 'boolean': return TrackingUiType.boolean;
    case 'booleanoptionaltext': return TrackingUiType.booleanOptionalText;
    case 'duration': return TrackingUiType.duration;
    case 'durationoptionaltext': return TrackingUiType.durationOptionalText;
    case 'number': return TrackingUiType.number;
    case 'time': return TrackingUiType.time;
    case 'scale': return TrackingUiType.scale;
    case 'scaleoptionaltext': return TrackingUiType.scaleOptionalText;
    case 'textrequired': return TrackingUiType.textRequired;
    case 'multitextrequired': return TrackingUiType.multiTextRequired;
    case 'streak': return TrackingUiType.streak;
    default: return TrackingUiType.boolean;
  }
}

/// Parse CSV bool string to bool
bool parseCsvBool(String? val) => val?.toLowerCase() == 'true';

/// Parse CSV number/empty to double?
double? parseCsvDouble(String? val) {
  if (val == null || val.isEmpty) return null;
  return double.tryParse(val);
}

/// Parse CSV number/empty to int?
int? parseCsvInt(String? val) {
  if (val == null || val.isEmpty) return null;
  return int.tryParse(val);
}

/// Routine model - for daily habits tracking
class Routine {
  final String id;
  final String name;
  final String nameEn;
  final String? icon;
  final String? description;
  final String? descriptionEn;
  final RoutineFrequency frequency;
  final String? reminderTime; // HH:mm format
  final bool isActive;
  final int? targetCount; // For countable routines (e.g., steps)
  final int currentCount;
  final bool isCounter; // true = count up to target, false = simple checkbox
  final String? unit; // e.g., '步', 'ml', '次'
  final List<RoutineCompletion> completionLog;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RoutineCategory? category; // null = auto-detect at display time
  final List<int>? scheduledDaysOfWeek;  // 1=Mon…7=Sun (ISO 8601). Used when frequency==weekly.
  final DateTime? scheduledDate;          // Used when frequency==scheduled.
  final String? iconImagePath;
  final bool voiceEnabled;
  final TrackingUiType trackingUiType;
  final String? categoryGroup;
  final double? trackingTarget;
  final double? trackingMin;
  final double? trackingMax;
  final double? trackingIncrement;
  final String? trackingUnit;
  final String? timeOfDay;
  final String? difficulty;
  final int? estimatedDuration;
  final bool isDefaultBundle;
  final bool customTargetAllowed;
  final String? twoMinVersionEn;
  final String? twoMinVersionCn;

  Routine({
    required this.id,
    required this.name,
    required this.nameEn,
    this.icon,
    this.description,
    this.descriptionEn,
    required this.frequency,
    this.reminderTime,
    this.isActive = true,
    this.targetCount,
    this.currentCount = 0,
    this.isCounter = false,
    this.unit,
    this.completionLog = const [],
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.scheduledDaysOfWeek,
    this.scheduledDate,
    this.iconImagePath,
    this.voiceEnabled = false,
    this.trackingUiType = TrackingUiType.boolean,
    this.categoryGroup,
    this.trackingTarget,
    this.trackingMin,
    this.trackingMax,
    this.trackingIncrement,
    this.trackingUnit,
    this.timeOfDay,
    this.difficulty,
    this.estimatedDuration,
    this.isDefaultBundle = false,
    this.customTargetAllowed = true,
    this.twoMinVersionEn,
    this.twoMinVersionCn,
  });

  /// Effective icon: explicit icon > category icon > auto-detect > fallback
  /// Returns the category PNG icon path, or null if no category is set.
  String? get effectiveIconPath {
    final cat = category ?? autoDetectCategory(name);
    if (cat != null && kCategoryIconPath.containsKey(cat)) {
      return kCategoryIconPath[cat];
    }
    return null;
  }

  String get effectiveIcon {
    if (icon != null && icon!.isNotEmpty) return icon!;
    final cat = category ?? autoDetectCategory(name);
    if (cat != null) return kCategoryEmoji[cat]!;
    return '⭐';
  }

  /// Human-readable frequency label (Chinese) — kept for compatibility.
  String get frequencyLabel => frequencyLabelFor(true);

  /// Locale-aware frequency label.
  String frequencyLabelFor(bool isZh) {
    switch (frequency) {
      case RoutineFrequency.daily:
        return isZh ? '每天' : 'Daily';
      case RoutineFrequency.weekly:
        if (scheduledDaysOfWeek == null || scheduledDaysOfWeek!.isEmpty) {
          return isZh ? '每周' : 'Weekly';
        }
        if (isZh) {
          const dayNamesZh = ['', '一', '二', '三', '四', '五', '六', '日'];
          final days = scheduledDaysOfWeek!.map((d) => dayNamesZh[d]).join('、');
          return '每周$days';
        } else {
          const dayNamesEn = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final days = scheduledDaysOfWeek!.map((d) => dayNamesEn[d]).join(', ');
          return 'Weekly: $days';
        }
      case RoutineFrequency.scheduled:
        if (scheduledDate == null) return isZh ? '指定日期' : 'Scheduled';
        return isZh
            ? '${scheduledDate!.month}月${scheduledDate!.day}日'
            : '${scheduledDate!.year}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}';
      case RoutineFrequency.adhoc:
        return isZh ? '随时' : 'On demand';
    }
  }

  Routine copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? icon,
    String? description,
    String? descriptionEn,
    RoutineFrequency? frequency,
    String? reminderTime,
    bool? isActive,
    int? targetCount,
    int? currentCount,
    bool? isCounter,
    String? unit,
    List<RoutineCompletion>? completionLog,
    DateTime? createdAt,
    DateTime? updatedAt,
    RoutineCategory? category,
    bool clearCategory = false,
    List<int>? scheduledDaysOfWeek,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    String? iconImagePath,
    bool clearIconImagePath = false,
    bool? voiceEnabled,
    TrackingUiType? trackingUiType,
    String? categoryGroup,
    double? trackingTarget,
    double? trackingMin,
    double? trackingMax,
    double? trackingIncrement,
    String? trackingUnit,
    String? timeOfDay,
    String? difficulty,
    int? estimatedDuration,
    bool? isDefaultBundle,
    bool? customTargetAllowed,
    String? twoMinVersionEn,
    String? twoMinVersionCn,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCounter: isCounter ?? this.isCounter,
      unit: unit ?? this.unit,
      completionLog: completionLog ?? this.completionLog,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: clearCategory ? null : (category ?? this.category),
      scheduledDaysOfWeek: scheduledDaysOfWeek ?? this.scheduledDaysOfWeek,
      scheduledDate: clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      iconImagePath: clearIconImagePath ? null : (iconImagePath ?? this.iconImagePath),
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      trackingUiType: trackingUiType ?? this.trackingUiType,
      categoryGroup: categoryGroup ?? this.categoryGroup,
      trackingTarget: trackingTarget ?? this.trackingTarget,
      trackingMin: trackingMin ?? this.trackingMin,
      trackingMax: trackingMax ?? this.trackingMax,
      trackingIncrement: trackingIncrement ?? this.trackingIncrement,
      trackingUnit: trackingUnit ?? this.trackingUnit,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isDefaultBundle: isDefaultBundle ?? this.isDefaultBundle,
      customTargetAllowed: customTargetAllowed ?? this.customTargetAllowed,
      twoMinVersionEn: twoMinVersionEn ?? this.twoMinVersionEn,
      twoMinVersionCn: twoMinVersionCn ?? this.twoMinVersionCn,
    );
  }

  /// Calculate streak (consecutive days, with 1-day grace period)
  int get streak {
    if (completionLog.isEmpty) return 0;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Filter out future-dated completions and sort newest first
    final sortedLogs = completionLog
        .where((log) {
          final logDate = DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day);
          return !logDate.isAfter(todayDate);
        })
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (sortedLogs.isEmpty) return 0;

    int count = 0;
    DateTime? lastDate;
    bool graceUsed = false;

    for (final log in sortedLogs) {
      final logDate = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );

      if (lastDate == null) {
        final yesterday = todayDate.subtract(const Duration(days: 1));

        if (logDate == todayDate || logDate == yesterday) {
          count = 1;
          lastDate = logDate;
        } else {
          break;
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (logDate == expectedDate) {
          count++;
          lastDate = logDate;
        } else if (logDate == lastDate) {
          continue;
        } else if (!graceUsed) {
          final skippedDate = lastDate.subtract(const Duration(days: 1));
          final expectedAfterSkip = skippedDate.subtract(const Duration(days: 1));
          if (logDate == expectedAfterSkip) {
            count += 2; // skip day counts toward streak
            lastDate = logDate;
            graceUsed = true;
          } else {
            break;
          }
        } else {
          break;
        }
      }
    }

    return count;
  }

  /// Whether the routine has a missed day but streak is protected by grace
  bool get inGrace {
    if (completionLog.isEmpty) return false;
    if (isCompletedToday) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final dayBefore = yesterday.subtract(const Duration(days: 1));
    return !isCompletedOn(yesterday) && isCompletedOn(dayBefore) && streak > 0;
  }

  /// Days remaining in grace period before streak resets (1 = still protected)
  int get graceDaysLeft => inGrace ? 1 : 0;

  /// Number of consecutive days missed (0 = completed today or yesterday)
  int get consecutiveMissedDays {
    if (isCompletedToday) return 0;
    var missed = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var cursor = todayDate.subtract(const Duration(days: 1));
    while (!isCompletedOn(cursor) && missed < 31) {
      missed++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return missed;
  }

  /// Check if completed on a specific date
  bool isCompletedOn(DateTime date) {
    return completionLog.any((log) =>
        log.completedAt.year == date.year &&
        log.completedAt.month == date.month &&
        log.completedAt.day == date.day);
  }

  /// Get completion record for a specific date
  RoutineCompletion? getCompletionOn(DateTime date) {
    try {
      return completionLog.firstWhere((log) =>
          log.completedAt.year == date.year &&
          log.completedAt.month == date.month &&
          log.completedAt.day == date.day);
    } catch (_) {
      return null;
    }
  }

  /// Check if completed today
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Get today's completion if exists
  RoutineCompletion? get todayCompletion => getCompletionOn(DateTime.now());

  /// Returns the display name for the current locale.
  String displayName(bool isZh) => isZh ? name : nameEn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'icon': icon,
      'description': description,
      'descriptionEn': descriptionEn,
      'frequency': frequency.name,
      'reminderTime': reminderTime,
      'isActive': isActive,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCounter': isCounter,
      'unit': unit,
      'completionLog': completionLog.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category?.name,
      'scheduledDaysOfWeek': scheduledDaysOfWeek,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'iconImagePath': iconImagePath,
      'voiceEnabled': voiceEnabled,
      'trackingUiType': trackingUiType.name,
      'categoryGroup': categoryGroup,
      'trackingTarget': trackingTarget,
      'trackingMin': trackingMin,
      'trackingMax': trackingMax,
      'trackingIncrement': trackingIncrement,
      'trackingUnit': trackingUnit,
      'timeOfDay': timeOfDay,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'isDefaultBundle': isDefaultBundle,
      'customTargetAllowed': customTargetAllowed,
      'twoMinVersionEn': twoMinVersionEn,
      'twoMinVersionCn': twoMinVersionCn,
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category'] as String?;
    final trackingUiTypeStr = json['trackingUiType'] as String?;
    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      frequency: RoutineFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RoutineFrequency.daily,
      ),
      reminderTime: json['reminderTime'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      targetCount: json['targetCount'] as int?,
      currentCount: json['currentCount'] as int? ?? 0,
      isCounter: json['isCounter'] as bool? ?? false,
      unit: json['unit'] as String?,
      completionLog: (json['completionLog'] as List<dynamic>?)
              ?.map((e) => RoutineCompletion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      category: categoryStr != null
          ? RoutineCategory.values.firstWhere(
              (c) => c.name == categoryStr,
              orElse: () => RoutineCategory.other,
            )
          : null,
      scheduledDaysOfWeek: (json['scheduledDaysOfWeek'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      iconImagePath: json['iconImagePath'] as String?,
      voiceEnabled: json['voiceEnabled'] as bool? ?? false,
      trackingUiType: trackingUiTypeStr != null
          ? TrackingUiType.values.firstWhere(
              (t) => t.name == trackingUiTypeStr,
              orElse: () => TrackingUiType.boolean,
            )
          : TrackingUiType.boolean,
      categoryGroup: json['categoryGroup'] as String?,
      trackingTarget: (json['trackingTarget'] as num?)?.toDouble(),
      trackingMin: (json['trackingMin'] as num?)?.toDouble(),
      trackingMax: (json['trackingMax'] as num?)?.toDouble(),
      trackingIncrement: (json['trackingIncrement'] as num?)?.toDouble(),
      trackingUnit: json['trackingUnit'] as String?,
      timeOfDay: json['timeOfDay'] as String?,
      difficulty: json['difficulty'] as String?,
      estimatedDuration: json['estimatedDuration'] as int?,
      isDefaultBundle: json['isDefaultBundle'] as bool? ?? false,
      customTargetAllowed: json['customTargetAllowed'] as bool? ?? true,
      twoMinVersionEn: json['twoMinVersionEn'] as String?,
      twoMinVersionCn: json['twoMinVersionCn'] as String?,
    );
  }
}

/// Routine completion record
class RoutineCompletion {
  final String id;
  final String routineId;
  final DateTime completedAt;
  final int? count; // For countable routines
  final String? notes;

  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.completedAt,
    this.count,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'completedAt': completedAt.toIso8601String(),
      'count': count,
      'notes': notes,
    };
  }

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) {
    return RoutineCompletion(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      count: json['count'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

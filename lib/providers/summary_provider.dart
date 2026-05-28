import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import 'entry_provider.dart';
import 'routine_provider.dart';

enum SummaryScope { daily, weekly, monthly }

/// Simple date range helper
class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange({required this.start, required this.end});
}

/// Provides aggregated statistics for the visual summary tab
class SummaryProvider extends ChangeNotifier {
  EntryProvider _entryProvider;
  RoutineProvider _routineProvider;
  SummaryScope _scope = SummaryScope.weekly;

  SummaryProvider(this._entryProvider, this._routineProvider);

  void update(EntryProvider ep, RoutineProvider rp) {
    _entryProvider = ep;
    _routineProvider = rp;
    notifyListeners();
  }

  bool get isLoading => _entryProvider.isLoading;

  SummaryScope get scope => _scope;
  void setScope(SummaryScope s) {
    _scope = s;
    notifyListeners();
  }

  /// Returns date range for current scope ending now,
  /// anchored to the earliest actual data date.
  _DateRange get _currentRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final earliestData = _earliestDataDate();

    switch (_scope) {
      case SummaryScope.daily:
        final defaultStart = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return _DateRange(
          start: earliestData != null && earliestData.isAfter(defaultStart)
              ? earliestData
              : defaultStart,
          end: today,
        );
      case SummaryScope.weekly:
        final defaultStart = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7 * 7));
        return _DateRange(
          start: earliestData != null && earliestData.isAfter(defaultStart)
              ? earliestData
              : defaultStart,
          end: today,
        );
      case SummaryScope.monthly:
        final defaultStart = DateTime(now.year, now.month - 5, 1);
        return _DateRange(
          start: earliestData != null && earliestData.isAfter(defaultStart)
              ? earliestData
              : defaultStart,
          end: today,
        );
    }
  }

  /// Returns the earliest date the user has any entry or routine completion.
  DateTime? _earliestDataDate() {
    final entries = _entryProvider.allEntries;
    final routines = _routineProvider.routines;

    DateTime? earliest;

    // Check entries
    for (final e in entries) {
      if (earliest == null || e.createdAt.isBefore(earliest)) {
        earliest = e.createdAt;
      }
    }

    // Check routine creation dates
    for (final r in routines) {
      final date = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      if (earliest == null || date.isBefore(earliest)) {
        earliest = date;
      }
    }

    // Check routine completion dates
    for (final r in routines) {
      for (final c in r.completionLog) {
        final date = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day);
        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
      }
    }

    return earliest;
  }

  /// Note counts per period
  List<({DateTime date, int count})> get noteCounts {
    final entries = _entryProvider.allEntries;
    final now = DateTime.now();

    switch (_scope) {
      case SummaryScope.daily:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final count = entries.where((e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day).length;
          return (date: day, count: count);
        });

      case SummaryScope.weekly:
        return List.generate(8, (i) {
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: (7 - i) * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final count = entries.where((e) =>
              e.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              e.createdAt.isBefore(weekEnd)).length;
          return (date: weekStart, count: count);
        });

      case SummaryScope.monthly:
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final count = entries.where((e) =>
              e.createdAt.year == month.year &&
              e.createdAt.month == month.month).length;
          return (date: month, count: count);
        });
    }
  }

  /// Routine completion rate per routine (display name → % 0.0-1.0)
  Map<String, double> routineCompletionRates({bool isZh = true}) {
    final routines = _routineProvider.routines;
    final range = _currentRange;
    final result = <String, double>{};

    for (final routine in routines) {
      if (!routine.isActive) continue;
      // Count days in range
      final totalDays = range.end.difference(range.start).inDays + 1;
      if (totalDays <= 0) continue;
      final completedDays = routine.completionLog.where((log) =>
          log.completedAt.isAfter(range.start.subtract(const Duration(days: 1))) &&
          log.completedAt.isBefore(range.end.add(const Duration(days: 1)))).length;
      result[routine.displayName(isZh)] = (completedDays / totalDays).clamp(0.0, 1.0);
    }
    return result;
  }

  static const Map<String, double> _emotionScores = {
    '😊': 5.0,
    '🥰': 5.0,
    '🤩': 5.0,
    '😌': 4.0,
    '😐': 3.0,
    '😴': 3.0,
    '😔': 2.0,
    '😢': 2.0,
    '😰': 2.0,
    '😤': 2.0,
    '😡': 1.0,
  };

  /// Emotion trend: list of ({date, score})
  List<({DateTime date, double score})> get emotionTrend {
    final entries = _entryProvider.allEntries
        .where((e) => e.emotion != null)
        .toList();
    final now = DateTime.now();

    switch (_scope) {
      case SummaryScope.daily:
        return List.generate(7, (i) {
          final day = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: 6 - i));
          final dayEntries = entries.where((e) =>
              e.createdAt.year == day.year &&
              e.createdAt.month == day.month &&
              e.createdAt.day == day.day);
          double score = 0;
          int count = 0;
          for (final e in dayEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: day, score: count > 0 ? score / count : 0.0);
        });

      case SummaryScope.weekly:
        return List.generate(8, (i) {
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: (7 - i) * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final weekEntries = entries.where((e) =>
              e.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
              e.createdAt.isBefore(weekEnd));
          double score = 0;
          int count = 0;
          for (final e in weekEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: weekStart, score: count > 0 ? score / count : 0.0);
        });

      case SummaryScope.monthly:
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final monthEntries = entries.where((e) =>
              e.createdAt.year == month.year &&
              e.createdAt.month == month.month);
          double score = 0;
          int count = 0;
          for (final e in monthEntries) {
            final s = _emotionScores[e.emotion] ?? 3.0;
            score += s;
            count++;
          }
          return (date: month, score: count > 0 ? score / count : 0.0);
        });
    }
  }

  /// Total entries across all time
  int get totalEntries => _entryProvider.allEntries.length;

  /// Map of sanitized date -> entry count for heatmap and streak computation
  Map<DateTime, int> get entriesPerDay {
    final map = <DateTime, int>{};
    for (final entry in _entryProvider.allEntries) {
      final day =
          DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  /// Current consecutive days with entries (starts from today if today has entries, else yesterday)
  int get currentStreak {
    final perDay = entriesPerDay;
    if (perDay.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime checkDay;
    if (perDay.containsKey(today)) {
      checkDay = today;
    } else {
      checkDay = today.subtract(const Duration(days: 1));
      if (!perDay.containsKey(checkDay)) return 0;
    }
    int streak = 0;
    while (perDay.containsKey(checkDay)) {
      streak++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Longest consecutive days with entries (all time)
  int get longestStreak {
    final perDay = entriesPerDay;
    if (perDay.isEmpty) return 0;
    final sorted = perDay.keys.toList()..sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// Average habit completion rate across all active routines (last 30-day window)
  double get recentHabitCompletionRate {
    final routines = _routineProvider.routines.where((r) => r.isActive).toList();
    if (routines.isEmpty) return 0.0;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    double totalRate = 0;
    for (final routine in routines) {
      final completed = routine.completionLog
          .where((log) =>
              log.completedAt.isAfter(thirtyDaysAgo) &&
              log.completedAt.isBefore(now.add(const Duration(days: 1))))
          .length;
      totalRate += (completed / 30.0).clamp(0.0, 1.0);
    }
    return totalRate / routines.length;
  }

  /// Mood distribution: map of emotion emoji -> count (all time)
  Map<String, int> get moodDistribution {
    final map = <String, int>{};
    for (final entry in _entryProvider.allEntries) {
      final emotion = entry.emotion;
      if (emotion != null && emotion.isNotEmpty) {
        map[emotion] = (map[emotion] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Top 5 tags by usage count (tagId → count)
  List<({String tagId, int count})> get topTags {
    final counts = <String, int>{};
    for (final entry in _entryProvider.allEntries) {
      for (final tagId in entry.tagIds) {
        counts[tagId] = (counts[tagId] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => (tagId: e.key, count: e.value))
        .toList();
  }

  /// Average word count per entry (mixed CJK + English word counting)
  double get averageEntryLength {
    final entries = _entryProvider.allEntries;
    if (entries.isEmpty) return 0;
    int totalWords = 0;
    for (final entry in entries) {
      totalWords += _countWords(entry.content);
    }
    return (totalWords / entries.length * 10).roundToDouble() / 10;
  }

  /// Weekday with most entries (1=Mon..7=Sun, null if no entries)
  int? get mostActiveDayOfWeek {
    final perDay = entriesPerDay;
    if (perDay.isEmpty) return null;
    final counts = List.filled(8, 0);
    for (final day in perDay.keys) {
      counts[day.weekday] += perDay[day]!;
    }
    int bestDay = 1;
    for (int i = 2; i <= 7; i++) {
      if (counts[i] > counts[bestDay]) bestDay = i;
    }
    return counts[bestDay] > 0 ? bestDay : null;
  }

  /// Hour of day with most entries (null if no entries)
  int? get mostActiveHour {
    final entries = _entryProvider.allEntries;
    if (entries.isEmpty) return null;
    final counts = List.filled(24, 0);
    for (final entry in entries) {
      counts[entry.createdAt.hour]++;
    }
    int bestHour = 0;
    for (int i = 1; i < 24; i++) {
      if (counts[i] > counts[bestHour]) bestHour = i;
    }
    return counts[bestHour] > 0 ? bestHour : null;
  }

  /// Tag-mood correlation: for each tag with ≥3 entries having emotions,
  /// compute average mood score (1-5 scale)
  List<({String tagId, double avgScore, int entryCount})>
      get tagMoodCorrelation {
    final entries = _entryProvider.allEntries
        .where((e) => e.emotion != null && e.emotion!.isNotEmpty)
        .toList();
    final tagScores = <String, List<double>>{};
    for (final entry in entries) {
      final score = _emotionScores[entry.emotion] ?? 3.0;
      for (final tagId in entry.tagIds) {
        tagScores.putIfAbsent(tagId, () => []);
        tagScores[tagId]!.add(score);
      }
    }
    final result = <({String tagId, double avgScore, int entryCount})>[];
    for (final e in tagScores.entries) {
      if (e.value.length < 3) continue;
      final avg =
          (e.value.reduce((a, b) => a + b) / e.value.length * 10).roundToDouble() / 10;
      result.add((tagId: e.key, avgScore: avg, entryCount: e.value.length));
    }
    result.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    return result;
  }

  /// Total number of checklist entries
  int get totalLists {
    return _entryProvider.allEntries
        .where((e) => e.format == EntryFormat.list)
        .length;
  }

  /// Average checklist completion rate across all lists (0.0–1.0)
  double get checklistCompletionRate {
    final lists = _entryProvider.allEntries
        .where((e) =>
            e.format == EntryFormat.list &&
            e.listItems != null &&
            e.listItems!.isNotEmpty)
        .toList();
    if (lists.isEmpty) return 0.0;
    double totalRate = 0;
    for (final list in lists) {
      final items = list.listItems!;
      if (items.isEmpty) continue;
      final done = items.where((i) => i.isDone).length;
      totalRate += done / items.length;
    }
    return lists.isEmpty
        ? 0.0
        : (totalRate / lists.length * 100).roundToDouble() / 100;
  }

  /// Total number of list items carried forward from previous days
  int get totalCarriedForward {
    int count = 0;
    for (final entry in _entryProvider.allEntries) {
      if (entry.listItems == null) continue;
      count += entry.listItems!.where((i) => i.fromPreviousDay).length;
    }
    return count;
  }

  /// Most common checklist item text across all lists (normalized to lowercase)
  /// Returns null if no items exist
  ({String text, int count})? get topChecklistItem {
    final counts = <String, int>{};
    for (final entry in _entryProvider.allEntries) {
      if (entry.listItems == null) continue;
      for (final item in entry.listItems!) {
        final normalized = item.text.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    final best =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (text: best.key, count: best.value);
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    final cjk = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF]');
    final cjkCount = cjk.allMatches(text).length;
    final nonCjk = text.replaceAll(cjk, ' ');
    final enCount =
        nonCjk.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    return cjkCount + enCount;
  }

  /// Build structured data payload for CT4 AI-generated insights.
  /// Used as the user prompt sent to the LLM.
  Map<String, dynamic> generateInsightsData({bool isZh = false}) {
    final perDay = entriesPerDay;
    final daysTracked = perDay.length;
    final moodDist = moodDistribution;
    final totalMoods = moodDist.values.fold<int>(0, (a, b) => a + b);

    String? topEmotion;
    int topEmotionCount = 0;
    for (final e in moodDist.entries) {
      if (e.value > topEmotionCount) {
        topEmotion = e.key;
        topEmotionCount = e.value;
      }
    }

    final trend = emotionTrend;
    final trendLabel = _trendLabel(trend);

    final activeDay = mostActiveDayOfWeek;
    final tags = topTags;

    final correlations = tagMoodCorrelation;

    final best = _bestMonth;

    final topTagNames = <String>[];
    for (final t in tags.take(3)) {
      topTagNames.add('$t ($t.count)');
    }

    return {
      'totalEntries': totalEntries,
      'daysTracked': daysTracked,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'topEmotion': topEmotion != null
          ? '$topEmotion (${(topEmotionCount / totalMoods * 100).round()}%)'
          : null,
      'moodTrend': trendLabel,
      'mostActiveDay': activeDay != null ? _weekdayName(activeDay) : null,
      'mostActiveHour': mostActiveHour,
      'topTags': topTagNames,
      'tagMoodCorrelation': correlations
          .take(3)
          .map((c) => {'tagId': c.tagId, 'avgMood': c.avgScore})
          .toList(),
      'checklistCompletion': checklistCompletionRate,
      'bestMonth': best != null
          ? '${best.month} (${best.entryCount} entries, avg mood ${best.avgMood.toStringAsFixed(1)})'
          : null,
      'wordCountAvg': averageEntryLength,
      'totalLists': totalLists,
    };
  }

  String _trendLabel(List<({DateTime date, double score})> trend) {
    if (trend.length < 2) return 'not enough data';
    final first = trend.first.score;
    final last = trend.last.score;
    if (last > first + 0.3) return 'improving';
    if (last < first - 0.3) return 'declining';
    return 'stable';
  }

  String _weekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[weekday];
  }

  ({String month, int entryCount, double avgMood})? get _bestMonth {
    final perDay = entriesPerDay;
    if (perDay.isEmpty) return null;
    final monthly = <String, List<DateTime>>{};
    for (final day in perDay.keys) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}';
      monthly.putIfAbsent(key, () => []);
      monthly[key]!.add(day);
    }
    final entries = _entryProvider.allEntries;
    final emotionEntries =
        entries.where((e) => e.emotion != null).toList();

    String? bestMonth;
    int bestEntries = 0;
    double bestMood = 0;

    for (final e in monthly.entries) {
      final count = e.value
          .fold<int>(0, (sum, d) => sum + (perDay[d] ?? 0));
      if (count > bestEntries) {
        bestEntries = count;
        bestMonth = e.key;
      }
    }

    if (bestMonth == null) return null;

    final monthEmotionEntries = emotionEntries.where((e) {
      final key =
          '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}';
      return key == bestMonth;
    }).toList();

    if (monthEmotionEntries.isNotEmpty) {
      double total = 0;
      for (final e in monthEmotionEntries) {
        total += _emotionScores[e.emotion] ?? 3.0;
      }
      bestMood = (total / monthEmotionEntries.length * 10).roundToDouble() / 10;
    }

    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final parts = bestMonth.split('-');
    final monthIdx = int.parse(parts[1]);
    final year = parts[0];

    return (
      month: '${monthNames[monthIdx]} $year',
      entryCount: bestEntries,
      avgMood: bestMood,
    );
  }

  /// Data fingerprint for cache invalidation in CT4.
  /// Changes when significant data changes.
  String get insightsDataFingerprint {
    return '${totalEntries}_${entriesPerDay.length}_${currentStreak}_${(checklistCompletionRate * 100).round()}';
  }
}

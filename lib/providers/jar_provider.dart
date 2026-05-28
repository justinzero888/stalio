import 'package:flutter/foundation.dart';
import 'entry_provider.dart';

/// Aggregates emotion data from EntryProvider for the emoji jar feature.
/// No new DB table needed — derives all data from existing entries.
class JarProvider extends ChangeNotifier {
  EntryProvider _entryProvider;

  JarProvider(this._entryProvider);

  /// Called by ChangeNotifierProxyProvider when EntryProvider updates
  void update(EntryProvider ep) {
    _entryProvider = ep;
    notifyListeners();
  }

  /// All years that have at least one entry
  List<int> get yearsWithData {
    final years = _entryProvider.allEntries
        .map((e) => e.createdAt.year)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a)); // newest first
    return years;
  }

  /// All emotions for a specific date (all non-null entry emotions that day)
  List<String> getDayEmotions(DateTime date) {
    return _entryProvider.allEntries
        .where((e) =>
            e.createdAt.year == date.year &&
            e.createdAt.month == date.month &&
            e.createdAt.day == date.day &&
            e.emotion != null &&
            !e.tagIds.contains('tag_private'))
        .map((e) => e.emotion!)
        .toList();
  }

  /// Dominant emotion per day for a given month (for shelf mini-jar)
  /// Returns Map<int, String?> where key = day-of-month
  Map<int, String?> getMonthEmotionMap(int year, int month) {
    final result = <int, String?>{};
    final monthEntries = _entryProvider.allEntries.where((e) =>
        e.createdAt.year == year &&
        e.createdAt.month == month &&
        e.emotion != null);

    final grouped = <int, Map<String, int>>{};
    for (final entry in monthEntries) {
      final day = entry.createdAt.day;
      grouped.putIfAbsent(day, () => {});
      final emotion = entry.emotion!;
      grouped[day]![emotion] = (grouped[day]![emotion] ?? 0) + 1;
    }

    for (final entry in grouped.entries) {
      final dominant = entry.value.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      result[entry.key] = dominant;
    }

    return result;
  }

  /// All emotions for a full year (for year card mini-jar, first 30)
  List<String> getYearEmotions(int year) {
    return _entryProvider.allEntries
        .where((e) => e.createdAt.year == year && e.emotion != null)
        .map((e) => e.emotion!)
        .take(30)
        .toList();
  }

  /// Entry count for a year
  int getYearEntryCount(int year) {
    return _entryProvider.allEntries
        .where((e) => e.createdAt.year == year)
        .length;
  }
}

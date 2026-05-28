import 'package:uuid/uuid.dart';
import '../models/routine.dart';
import '../core/services/storage_service.dart';

/// Repository for Routine data access
/// Handles daily habits and their completions
class RoutineRepository {
  final StorageService _storage;
  final _uuid = const Uuid();

  RoutineRepository(this._storage);

  /// Get all routines
  Future<List<Routine>> getAll() async {
    final routines = await _storage.getRoutines();
    routines.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return routines;
  }

  /// Get only active routines
  Future<List<Routine>> getActive() async {
    final routines = await getAll();
    return routines.where((r) => r.isActive).toList();
  }

  /// Get only paused (inactive) routines
  Future<List<Routine>> getPaused() async {
    final routines = await getAll();
    return routines.where((r) => !r.isActive).toList();
  }

  /// Get routines that have reminders set
  Future<List<Routine>> getWithReminders() async {
    final routines = await getAll();
    return routines.where((r) => r.reminderTime != null).toList();
  }

  /// Get a single routine by ID
  Future<Routine?> getById(String id) async {
    final routines = await getAll();
    try {
      return routines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new routine
  Future<Routine> create({
    required String name,
    required String nameEn,
    required RoutineFrequency frequency,
    String? reminderTime,
    int? targetCount,
    String? unit,
    bool isCounter = false,
    bool isActive = true,
    RoutineCategory? category,
    List<int>? scheduledDaysOfWeek,
    DateTime? scheduledDate,
    String? iconImagePath,
    bool voiceEnabled = false,
  }) async {
    final now = DateTime.now();
    final routine = Routine(
      id: _uuid.v4(),
      name: name,
      nameEn: nameEn,
      frequency: frequency,
      reminderTime: reminderTime,
      isActive: isActive,
      targetCount: targetCount,
      isCounter: isCounter,
      unit: unit,
      completionLog: [],
      createdAt: now,
      updatedAt: now,
      category: category,
      scheduledDaysOfWeek: scheduledDaysOfWeek,
      scheduledDate: scheduledDate,
      iconImagePath: iconImagePath,
      voiceEnabled: voiceEnabled,
    );
    await _storage.addRoutine(routine);
    return routine;
  }

  /// Insert a fully-constructed routine (used for import).
  /// Does not generate a new ID — preserves the one from the source.
  Future<void> insertFull(Routine routine) async {
    await _storage.addRoutine(routine);
  }

  /// Update an existing routine
  Future<Routine?> update(Routine routine) async {
    final updated = routine.copyWith(updatedAt: DateTime.now());
    await _storage.updateRoutine(updated);
    return updated;
  }

  /// Delete a routine
  Future<void> delete(String id) async {
    await _storage.deleteRoutine(id);
  }

  /// Toggle routine active status
  Future<Routine?> toggleActive(String id) async {
    final routine = await getById(id);
    if (routine == null) return null;
    
    final updated = routine.copyWith(
      isActive: !routine.isActive,
      updatedAt: DateTime.now(),
    );
    await _storage.updateRoutine(updated);
    return updated;
  }

  /// Mark a routine as complete for a specific date (defaults to today)
  Future<Routine?> markComplete(String routineId, {DateTime? date, int? count, String? notes}) async {
    final routine = await getById(routineId);
    if (routine == null) return null;

    final targetDate = date ?? DateTime.now();

    final completion = RoutineCompletion(
      id: _uuid.v4(),
      routineId: routineId,
      completedAt: targetDate,
      count: count,
      notes: notes,
    );

    // Remove existing completion for that date if any
    final updatedLog = routine.completionLog.where((log) {
      return !(log.completedAt.year == targetDate.year &&
          log.completedAt.month == targetDate.month &&
          log.completedAt.day == targetDate.day);
    }).toList();

    // Add new completion
    updatedLog.add(completion);

    final updated = routine.copyWith(
      completionLog: updatedLog,
      updatedAt: DateTime.now(),
    );
    await _storage.updateRoutine(updated);
    return updated;
  }

  /// Unmark (remove) completion for a specific date (defaults to today)
  Future<Routine?> unmarkComplete(String routineId, {DateTime? date}) async {
    final routine = await getById(routineId);
    if (routine == null) return null;

    final targetDate = date ?? DateTime.now();

    final updatedLog = routine.completionLog.where((log) {
      return !(log.completedAt.year == targetDate.year &&
          log.completedAt.month == targetDate.month &&
          log.completedAt.day == targetDate.day);
    }).toList();

    final updated = routine.copyWith(
      completionLog: updatedLog,
      updatedAt: DateTime.now(),
    );
    await _storage.updateRoutine(updated);
    return updated;
  }

  /// Update count for a specific date (for countable routines like steps, water)
  Future<Routine?> updateDateCount(String routineId, int count, {DateTime? date}) async {
    return markComplete(routineId, count: count, date: date);
  }

  /// Check if routine is completed today
  Future<bool> isCompletedToday(String routineId) async {
    final routine = await getById(routineId);
    return routine?.isCompletedToday ?? false;
  }

  /// Get today's completion for a routine
  Future<RoutineCompletion?> getTodayCompletion(String routineId) async {
    final routine = await getById(routineId);
    return routine?.todayCompletion;
  }

  /// Get completion history for a date range
  Future<List<RoutineCompletion>> getCompletionsInRange(
    String routineId,
    DateTime start,
    DateTime end,
  ) async {
    final routine = await getById(routineId);
    if (routine == null) return [];

    return routine.completionLog.where((log) =>
        log.completedAt.isAfter(start.subtract(const Duration(days: 1))) &&
        log.completedAt.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  /// Get streak count (consecutive days completed)
  Future<int> getStreak(String routineId) async {
    final routine = await getById(routineId);
    if (routine == null || routine.completionLog.isEmpty) return 0;

    // Sort completions by date descending
    final sorted = List<RoutineCompletion>.from(routine.completionLog)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final log in sorted) {
      final logDate = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      final check = DateTime(checkDate.year, checkDate.month, checkDate.day);

      if (logDate == check || logDate == check.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = logDate;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Initialize with default routines if empty
  Future<void> initializeDefaults() async {
    final routines = await getAll();
    if (routines.isEmpty) {
      // Default routines are already created in StorageService.init()
      // This is a placeholder for any additional initialization
    }
  }
}

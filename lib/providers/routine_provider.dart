import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../repositories/routine_repository.dart';
import '../core/services/notification_service.dart';
import '../core/services/voice_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// Provider for managing routines (daily habits)
/// Uses RoutineRepository for data access
class RoutineProvider extends ChangeNotifier {
  final RoutineRepository _repository;
  
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;
  Timer? _foregroundTimer;
  final Set<String> _recentlySpoken = {};

  RoutineProvider(this._repository);

  // Getters
  List<Routine> get routines => _routines;
  List<Routine> get activeRoutines => _routines.where((r) => r.isActive).toList();
  List<Routine> get inactiveRoutines => _routines.where((r) => !r.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generate Schedule objects from active routines and their completion logs.
  /// For each active routine, produces one Schedule per completion entry,
  /// plus an uncompleted Schedule for today if not yet done.
  List<Schedule> get schedules {
    final List<Schedule> result = [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final routine in _routines.where((r) => r.isActive)) {
      bool hasToday = false;

      // Create a schedule for each completion log entry
      for (final log in routine.completionLog) {
        final logDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        result.add(Schedule(
          id: log.id,
          routineId: routine.id,
          scheduledDate: logDate,
          completedAt: log.completedAt,
          notes: log.notes,
        ));
        if (logDate == todayDate) {
          hasToday = true;
        }
      }

      // If no completion for today, add an uncompleted schedule
      if (!hasToday) {
        result.add(Schedule(
          id: '${routine.id}_$todayDate',
          routineId: routine.id,
          scheduledDate: todayDate,
          completedAt: null,
        ));
      }
    }

    return result;
  }

  /// Load all routines from storage
  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routines = await _repository.getAll();
      // Reschedule notifications for all active routines
      NotificationService.rescheduleAll(_routines, false);
      // Speak recently-missed reminders if voice is enabled
      _speakRecentReminders(false);
      // Start periodic foreground check for reminders arriving while app is open
      _startForegroundCheck();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new routine
  Future<Routine?> addRoutine({
    required String name,
    required String nameEn,
    required RoutineFrequency frequency,
    String? reminderTime,
    int? targetCount,
    String? unit,
    bool isCounter = false,
    RoutineCategory? category,
    List<int>? scheduledDaysOfWeek,
    DateTime? scheduledDate,
    String? iconImagePath,
    bool voiceEnabled = false,
  }) async {
    _error = null;

    try {
      final routine = await _repository.create(
        name: name,
        nameEn: nameEn,
        frequency: frequency,
        reminderTime: reminderTime,
        targetCount: targetCount,
        unit: unit,
        isCounter: isCounter,
        category: category,
        scheduledDaysOfWeek: scheduledDaysOfWeek,
        scheduledDate: scheduledDate,
        iconImagePath: iconImagePath,
        voiceEnabled: voiceEnabled,
      );
      _routines.add(routine);
      notifyListeners();
      return routine;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an existing routine
  Future<void> updateRoutine(Routine routine) async {
    _error = null;
    
    try {
      final updated = await _repository.update(routine);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a routine
  Future<void> deleteRoutine(String id) async {
    _error = null;
    
    try {
      await _repository.delete(id);
      _routines.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle routine active/paused status
  Future<void> toggleActive(String id) async {
    _error = null;
    
    try {
      final updated = await _repository.toggleActive(id);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a routine as complete for a specific date (defaults to today)
  Future<void> completeRoutine(String id, {DateTime? date, int? count, String? notes}) async {
    _error = null;
    
    try {
      final updated = await _repository.markComplete(id, date: date, count: count, notes: notes);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unmark completion for a specific date (defaults to today)
  Future<void> unmarkRoutine(String id, {DateTime? date}) async {
    _error = null;
    
    try {
      final updated = await _repository.unmarkComplete(id, date: date);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle completion for a specific date (defaults to today)
  Future<void> toggleComplete(String id, {DateTime? date}) async {
    final routine = _routines.firstWhere((r) => r.id == id);
    final targetDate = date ?? DateTime.now();
    if (routine.isCompletedOn(targetDate)) {
      await unmarkRoutine(id, date: targetDate);
    } else {
      await completeRoutine(id, date: targetDate);
    }
  }

  /// Update count for a specific date (for countable routines)
  Future<void> updateCount(String id, int count, {DateTime? date}) async {
    _error = null;
    
    try {
      final updated = await _repository.updateDateCount(id, count, date: date);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get routine by ID
  Routine? getRoutineById(String id) {
    try {
      return _routines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get today's completion for a routine
  RoutineCompletion? getTodayCompletion(String routineId) {
    final routine = getRoutineById(routineId);
    return routine?.todayCompletion;
  }

  /// Get streak for a routine
  Future<int> getStreak(String routineId) async {
    return _repository.getStreak(routineId);
  }

  /// Get routines that should appear for a given date based on their schedule.
  List<Routine> getRoutinesForDate(DateTime date) {
    final weekday = date.weekday; // 1=Mon…7=Sun
    return _routines.where((r) {
      if (!r.isActive) return false;
      switch (r.frequency) {
        case RoutineFrequency.daily:
          return true;
        case RoutineFrequency.weekly:
          if (r.scheduledDaysOfWeek == null || r.scheduledDaysOfWeek!.isEmpty) {
            return true; // backward compat: no day set → every day
          }
          return r.scheduledDaysOfWeek!.contains(weekday);
        case RoutineFrequency.scheduled:
          final sd = r.scheduledDate;
          return sd != null &&
              sd.year == date.year &&
              sd.month == date.month &&
              sd.day == date.day;
        case RoutineFrequency.adhoc:
          return false;
      }
    }).toList();
  }

  /// Returns true if a routine was scheduled for [date] but not completed,
  /// and [date] is strictly before today (i.e., the day has ended).
  bool isMissedOn(Routine routine, DateTime date) {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final dateNorm = DateTime(date.year, date.month, date.day);
    return dateNorm.isBefore(todayNorm) &&
        !routine.isCompletedOn(date) &&
        getRoutinesForDate(date).any((r) => r.id == routine.id);
  }

  List<Routine> get adhocRoutines =>
      _routines.where((r) => r.isActive && r.frequency == RoutineFrequency.adhoc).toList();

  /// Export all routines as a JSON string (version-stamped).
  String exportRoutinesJson() {
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'routines': _routines.map((r) => r.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  /// Import routines from a JSON string.
  /// Returns a record with (imported, skipped) counts.
  Future<({int imported, int skipped})> importRoutinesJson(String json) async {
    int imported = 0;
    int skipped = 0;
    final existingIds = _routines.map((r) => r.id).toSet();

    final Map<String, dynamic> payload = jsonDecode(json) as Map<String, dynamic>;
    final List<dynamic> list = payload['routines'] as List<dynamic>? ?? [];

    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id != null && existingIds.contains(id)) {
        skipped++;
        continue;
      }
      try {
        final routine = Routine.fromJson(map);
        // Insert via repository with all existing fields preserved
        await _repository.insertFull(routine);
        _routines.add(routine);
        existingIds.add(routine.id);
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    if (imported > 0) notifyListeners();
    return (imported: imported, skipped: skipped);
  }

  void _startForegroundCheck() {
    _foregroundTimer?.cancel();
    _recentlySpoken.clear();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _speakRecentReminders(false);
    });
  }

  @override
  void dispose() {
    _foregroundTimer?.cancel();
    super.dispose();
  }

  Future<void> _speakRecentReminders(bool isZh) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voiceEnabled = prefs.getBool('voice_notifications_enabled') ?? false;
      if (!voiceEnabled) return;

      await VoiceNotificationService.init();

      final now = DateTime.now();
      for (final r in _routines) {
        if (!r.isActive || !r.voiceEnabled || r.reminderTime == null) continue;
        final parts = r.reminderTime!.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;
        final reminderToday = DateTime(now.year, now.month, now.day, hour, minute);
        final diff = now.difference(reminderToday);
        if (diff.inMinutes >= 0 && diff.inMinutes < 2) {
          if (_recentlySpoken.contains(r.id)) continue; // Already spoken this window
          _recentlySpoken.add(r.id);
          final text = r.displayName(isZh);
          final desc = isZh
              ? (r.description ?? '')
              : (r.descriptionEn ?? r.description ?? '');
          final spokenText = desc.isNotEmpty ? '$text — $desc' : text;
          await VoiceNotificationService.speak(
            spokenText,
            language: isZh ? 'zh-CN' : 'en-US',
          );
          break; // Speak only one to avoid flooding
        }
      }
    } catch (_) {
      // Voice is best-effort — never crash on failure
    }
  }
}

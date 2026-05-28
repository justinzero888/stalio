import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/routine.dart';
import 'voice_notification_service.dart';

/// Local-only notification service tied to routine reminders.
/// Zero data leaves the device — fully aligned with privacy claim.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'routine_reminders';
  static const _channelName = 'Routine Reminders';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _log('Starting init...');
    
    try {
      tzData.initializeTimeZones();
      final localTz = _detectLocalTimezone();
      tz.setLocalLocation(localTz);
      _log('Timezone set: ${localTz.name}');
    } catch (e) {
      _log('Timezone FAILED: $e');
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _log('Plugin initialized');

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _log('Requested notification permission');

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily habit and routine reminders',
      importance: Importance.defaultImportance,
      enableVibration: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    _log('Init complete');
  }

  static Future<String?> _voicePayload(Routine routine, bool isZh) async {
    if (!routine.voiceEnabled) return null;
    final prefs = await SharedPreferences.getInstance();
    final globalVoice = prefs.getBool('voice_notifications_enabled') ?? false;
    if (!globalVoice) return null;
    return json.encode({
      'voice': 'true',
      'text': routine.displayName(isZh),
      'lang': isZh ? 'zh-CN' : 'en-US',
    });
  }

  static Future<void> scheduleRoutine(Routine routine, bool isZh) async {
    if (!_initialized) return;
    if (routine.reminderTime == null) return;
    if (!routine.isActive) return;

    await cancelRoutine(routine.id, isZh);

    final parts = routine.reminderTime!.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    try {
      final title = routine.icon ?? routine.effectiveIcon;
      final body = routine.displayName(isZh);
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      _log('Scheduling: "$body" at ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2,'0')} (now: ${now.hour}:${now.minute.toString().padLeft(2,'0')})');

      final details = _notificationDetails();
      final payload = await _voicePayload(routine, isZh);

      if (routine.frequency == RoutineFrequency.weekly && routine.scheduledDaysOfWeek != null) {
        for (final day in routine.scheduledDaysOfWeek!) {
          final weekdayDate = _nextWeekday(now, day, hour, minute);
          final tzWeekday = tz.TZDateTime.from(weekdayDate, tz.local);
          await _plugin.zonedSchedule(
            id: _routineNotificationId(routine, day),
            title: title,
            body: body,
            scheduledDate: tzWeekday,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: payload,
          );
        }
        _log('Scheduled weekly: $body (${routine.scheduledDaysOfWeek!.length} days)');
        return;
      }

      if (routine.frequency == RoutineFrequency.scheduled && routine.scheduledDate != null) {
        final sched = routine.scheduledDate!;
        final dt = DateTime(sched.year, sched.month, sched.day, hour, minute);
        if (dt.isBefore(now)) {
          _log('Skipping one-time routine: already past');
          return;
        }
        scheduledDate = dt;
      }

      // Note: matchDateTimeComponents removed — causes silent failure on iOS.
      // Daily repeat is achieved by rescheduleAll() running on every app launch.
      await _plugin.zonedSchedule(
        id: _routineNotificationId(routine, 0),
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      _log('Scheduled: $body at $tzScheduled');
    } catch (e) {
      _log('Schedule failed: $e');
    }
  }

  static Future<void> cancelRoutine(String routineId, bool isZh) async {
    if (!_initialized) return;
    final baseId = routineId.hashCode.abs();
    for (var i = 0; i <= 7; i++) {
      await _plugin.cancel(id: baseId + i);
    }
  }

  static Future<void> rescheduleAll(List<Routine> routines, bool isZh) async {
    if (!_initialized) return;
    _log('Rescheduling ${routines.where((r) => r.isActive && r.reminderTime != null).length} active routines');
    for (final r in routines) {
      if (r.isActive && r.reminderTime != null) {
        await scheduleRoutine(r, isZh);
      }
    }
  }

  static int _routineNotificationId(Routine routine, int subId) {
    return routine.id.hashCode.abs() + subId;
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Daily habit and routine reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }

  static DateTime _nextWeekday(DateTime now, int weekday, int hour, int minute) {
    var date = DateTime(now.year, now.month, now.day, hour, minute);
    while (date.weekday != weekday || date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  static void _log(String msg) {
    final ts = DateTime.now().toIso8601String();
    final line = '$ts 📢 $msg';
    debugPrint(line);
  }

  /// Map POSIX timezone abbreviation to IANA location.
  static tz.Location _detectLocalTimezone() {
    final abbr = DateTime.now().timeZoneName;
    final offset = DateTime.now().timeZoneOffset;
    // Common abbreviations → IANA
    const map = {
      'EDT': 'America/New_York',
      'EST': 'America/New_York',
      'CDT': 'America/Chicago',
      'CST': 'America/Chicago',
      'MDT': 'America/Denver',
      'MST': 'America/Denver',
      'PDT': 'America/Los_Angeles',
      'PST': 'America/Los_Angeles',
      'BST': 'Europe/London',
      'GMT': 'Europe/London',
      'CEST': 'Europe/Berlin',
      'CET': 'Europe/Berlin',
      'IST': 'Asia/Kolkata',
      'JST': 'Asia/Tokyo',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney',
    };
    if (map.containsKey(abbr)) return tz.getLocation(map[abbr]!);

    // Fallback: search by offset (UTC+X hours)
    for (final name in tz.timeZoneDatabase.locations.keys) {
      try {
        final loc = tz.getLocation(name);
        final now = tz.TZDateTime.now(loc);
        if (now.timeZoneOffset == offset) return loc;
      } catch (_) {}
    }
    return tz.UTC;
  }
}

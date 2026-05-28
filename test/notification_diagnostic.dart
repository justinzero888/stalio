/// Notification diagnostic — verifies the full pipeline
/// Run with: dart run test/notification_diagnostic.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzData.initializeTimeZones();

  final plugin = FlutterLocalNotificationsPlugin();

  print('=== Notification Diagnostic ===');

  // 1. Check timezone initialization
  try {
    final now = tz.TZDateTime.now(tz.local);
    print('✅ Timezone OK: $now');
  } catch (e) {
    print('❌ Timezone failed: $e');
  }

  // 2. Initialize plugin
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await plugin.initialize(
    settings: const InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    ),
  );
  print('✅ Plugin initialized');

  // 3. Check pending notifications
  try {
    final pending = await plugin.pendingNotificationRequests();
    print('✅ Pending notifications: ${pending.length}');
    for (final p in pending) {
      print('   - ID: ${p.id}, Title: ${p.title}');
    }
  } catch (e) {
    print('⏭  Pending check: $e');
  }

  // 4. Schedule a test notification 30 seconds from now
  final now = tz.TZDateTime.now(tz.local);
  final scheduledDate = now.add(const Duration(seconds: 30));
  print('⏰ Scheduling test notification at: $scheduledDate');

  try {
    await plugin.zonedSchedule(
      id: 99999,
      title: '🔔 Test Notification',
      body: 'If you see this, notifications work!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          channelDescription: 'Diagnostic test',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    print('✅ Test notification scheduled for 30 seconds from now');
  } catch (e) {
    print('❌ Failed to schedule: $e');
  }

  // 5. Verify it was scheduled
  try {
    final pending = await plugin.pendingNotificationRequests();
    print('✅ After scheduling, pending: ${pending.length}');
    final testNotif = pending.where((p) => p.id == 99999);
    print('   Test notif (id=99999) found: ${testNotif.isNotEmpty}');
  } catch (e) {
    print('⏭  Verification: $e');
  }

  print('\n=== Wait 30 seconds for notification ===');
  await Future.delayed(const Duration(seconds: 5));
  print('App will stay alive for 35 seconds. Put it in background to see notification.');
  await Future.delayed(const Duration(seconds: 30));
  print('Done. Did you see the notification?');
}

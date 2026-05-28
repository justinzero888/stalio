import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/device_service.dart';
import 'core/services/purchases_service.dart';
import 'core/services/config_service.dart';
import 'core/services/notification_service.dart';
import 'models/entry.dart';

const _rcApiKey = String.fromEnvironment('RC_API_KEY');
const _uuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode || kProfileMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  await DeviceService.getDeviceId();

  final storageService = StorageService();
  await storageService.init();

  final prefs = await SharedPreferences.getInstance();

  // Reset previous trial state on fresh install
  final wasPreview = prefs.getBool('entitlement_was_preview');
  if (wasPreview == null) {
    await prefs.remove('trial_token');
    await prefs.remove('trial_started_at');
    await prefs.remove('trial_device_id');
  }

  // Seed demo entries for keepsake card inspection (debug builds only)
  if (kDebugMode) {
    await _seedDemoEntries(storageService, prefs);
  }

  final purchasesService = PurchasesService();
  await purchasesService.init(
    unifiedKey: _rcApiKey.isNotEmpty
        ? _rcApiKey
        : kDebugMode
            ? 'test_FFZAekOZQXGwwReuLkrvQLTjyOP'
            : null,
  );

  ConfigService.fetch();
  await NotificationService.init();

  runApp(BlinkingApp(
    storageService: storageService,
    purchasesService: purchasesService,
  ));
}

Future<void> _seedDemoEntries(StorageService storage, SharedPreferences prefs) async {
  if (prefs.getBool('demo_entries_seeded') == true) return;
  await prefs.setBool('demo_entries_seeded', true);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tags = ['tag_welcome', 'tag_gratitude', 'tag_insight', 'tag_daily'];

  final entries = [
    _demoEntry(today, tags[0], '😊', '今日阳光正好，微风不燥。'), // 12 chars
    _demoEntry(today.subtract(const Duration(days: 1)), tags[1], '😌',
        '感谢清晨的第一杯咖啡，感谢傍晚时分偶遇的老友，感谢生活中每一个不经意的温暖瞬间。'),
    _demoEntry(today.subtract(const Duration(days: 1)), tags[2], '😌',
        'Sometimes the smallest step in the right direction ends up being the biggest step of your life. Tip toe if you must, but take the step. The journey of a thousand miles begins with a single breath of courage.'),
    _demoEntry(today.subtract(const Duration(days: 2)), tags[0], '😊', '静。'), // 1 char
    _demoEntry(today.subtract(const Duration(days: 2)), tags[2], '😌',
        '人生如茶，第一道苦若生命，第二道甜似爱情，第三道淡如清风。品茶亦是品人生，在沸水中翻腾，在时光里沉淀，最终归于平淡。或许这就是生活的真谛——在喧嚣中守住内心的宁静，在浮躁中寻找片刻的从容。'),
    _demoEntry(today.subtract(const Duration(days: 3)), tags[3], '😊',
        '今天的晨跑格外畅快。六点的公园几乎没人，只有几只早起的鸟儿在枝头唱歌。跑了五公里，汗水浸透了衣服，但那种通透的感觉无可替代。'),
    _demoEntry(today.subtract(const Duration(days: 3)), tags[1], '😢',
        'The rain tapped softly against the window as I sat with my thoughts. There is something beautiful about melancholy — it sharpens the edges of memory and makes the ordinary feel profound. I miss the sound of your laughter in the morning.'),
    _demoEntry(today.subtract(const Duration(days: 4)), tags[3], '😡',
        'Work has been overwhelming lately. Back-to-back meetings, endless emails, and a growing sense that I am running on a treadmill going nowhere. I need to pause. I need to breathe. I need to remember why I started doing this in the first place. Tomorrow is another chance to reset.'),
  ];

  final existing = await storage.getEntries();
  for (final entry in entries) {
    if (!existing.any((e) => e.id == entry.id)) {
      await storage.addEntry(entry);
    }
  }
}

Entry _demoEntry(DateTime date, String tagId, String emotion, String content) {
  return Entry(
    id: _uuid.v4(),
    type: EntryType.freeform,
    content: content,
    emotion: emotion,
    createdAt: date,
    updatedAt: date,
    tagIds: [tagId],
  );
}

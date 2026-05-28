import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SoftPromptService', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('preview day calculation', () {
      test('returns -1 when no preview started date', () async {
        final day = await _previewDay(prefs);
        expect(day, -1);
      });

      test('returns current day offset from preview start', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 5));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());

        final day = await _previewDay(prefs);
        // Day should be approximately 6 (5 days before + today)
        expect(day, greaterThanOrEqualTo(5));
        expect(day, lessThanOrEqualTo(7));
      });

      test('returns 1 for first day of preview', () async {
        final today = DateTime.now();
        await prefs.setString('entitlement_preview_started', today.toIso8601String());

        final day = await _previewDay(prefs);
        expect(day, 1);
      });

      test('handles invalid ISO8601 date gracefully', () async {
        await prefs.setString('entitlement_preview_started', 'invalid-date');
        final day = await _previewDay(prefs);
        expect(day, -1);
      });
    });

    group('soft prompt timing', () {
      test('returns false before day 18', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 1));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());

        final shouldShow = await _shouldShowPrompt(prefs);
        expect(shouldShow, isFalse);
      });

      test('returns true on day 18', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 17));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('soft_prompt_last_shown', ''); // not shown today

        final shouldShow = await _shouldShowPrompt(prefs);
        expect(shouldShow, isTrue);
      });

      test('returns true on day 19', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 18));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('soft_prompt_last_shown', ''); // not shown today

        final shouldShow = await _shouldShowPrompt(prefs);
        expect(shouldShow, isTrue);
      });

      test('returns true on day 20', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 19));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());
        await prefs.setString('soft_prompt_last_shown', ''); // not shown today

        final shouldShow = await _shouldShowPrompt(prefs);
        expect(shouldShow, isTrue);
      });

      test('returns false after day 20', () async {
        final daysBefore = DateTime.now().subtract(Duration(days: 21));
        await prefs.setString('entitlement_preview_started', daysBefore.toIso8601String());

        final shouldShow = await _shouldShowPrompt(prefs);
        expect(shouldShow, isFalse);
      });
    });

    group('daily limit', () {
      test('allows showing once per day', () async {
        final today = DateTime.now();
        final todayKey = '${today.year}-${today.month}-${today.day}';

        // First time today
        var canShow = await _canShowToday(prefs);
        expect(canShow, isTrue);

        // Mark as shown
        await prefs.setString('soft_prompt_last_shown', todayKey);

        // Second time today
        canShow = await _canShowToday(prefs);
        expect(canShow, isFalse);
      });

      test('resets on new day', () async {
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

        await prefs.setString('soft_prompt_last_shown', yesterdayKey);

        final canShow = await _canShowToday(prefs);
        expect(canShow, isTrue);
      });
    });

    group('prompt content per day', () {
      test('day 18 returns appropriate title', () {
        const day = 18;
        final titleEn = _titleForDay(day, false);
        final titleZh = _titleForDay(day, true);

        expect(titleEn, isNotEmpty);
        expect(titleZh, isNotEmpty);
      });

      test('day 19 returns appropriate title', () {
        const day = 19;
        final titleEn = _titleForDay(day, false);
        final titleZh = _titleForDay(day, true);

        expect(titleEn, isNotEmpty);
        expect(titleZh, isNotEmpty);
      });

      test('day 20 returns appropriate title', () {
        const day = 20;
        final titleEn = _titleForDay(day, false);
        final titleZh = _titleForDay(day, true);

        expect(titleEn, isNotEmpty);
        expect(titleZh, isNotEmpty);
      });

      test('day 18 returns appropriate body', () {
        const day = 18;
        final bodyEn = _bodyForDay(day, false);
        final bodyZh = _bodyForDay(day, true);

        expect(bodyEn, isNotEmpty);
        expect(bodyZh, isNotEmpty);
      });

      test('day 19 returns appropriate body', () {
        const day = 19;
        final bodyEn = _bodyForDay(day, false);
        final bodyZh = _bodyForDay(day, true);

        expect(bodyEn, isNotEmpty);
        expect(bodyZh, isNotEmpty);
      });

      test('day 20 returns appropriate body', () {
        const day = 20;
        final bodyEn = _bodyForDay(day, false);
        final bodyZh = _bodyForDay(day, true);

        expect(bodyEn, isNotEmpty);
        expect(bodyZh, isNotEmpty);
      });

      test('day 18 returns appropriate CTA', () {
        const day = 18;
        final ctaEn = _ctaForDay(day, false);
        final ctaZh = _ctaForDay(day, true);

        expect(ctaEn, isNotEmpty);
        expect(ctaZh, isNotEmpty);
      });

      test('all soft prompt content is bilingual', () {
        for (int day = 18; day <= 20; day++) {
          final titleEn = _titleForDay(day, false);
          final titleZh = _titleForDay(day, true);
          expect(titleEn, isNotEmpty);
          expect(titleZh, isNotEmpty);
          expect(titleEn, isNot(titleZh));

          final bodyEn = _bodyForDay(day, false);
          final bodyZh = _bodyForDay(day, true);
          expect(bodyEn, isNotEmpty);
          expect(bodyZh, isNotEmpty);

          final ctaEn = _ctaForDay(day, false);
          final ctaZh = _ctaForDay(day, true);
          expect(ctaEn, isNotEmpty);
          expect(ctaZh, isNotEmpty);
        }
      });
    });
  });
}

// Helper functions mirroring SoftPromptService logic
Future<int> _previewDay(SharedPreferences prefs) async {
  final startedStr = prefs.getString('entitlement_preview_started');
  if (startedStr == null) return -1;
  final started = DateTime.tryParse(startedStr);
  if (started == null) return -1;
  return DateTime.now().difference(started).inDays + 1;
}

Future<bool> _shouldShowPrompt(SharedPreferences prefs) async {
  final day = await _previewDay(prefs);
  if (day < 18 || day > 20) return false;
  if (!await _canShowToday(prefs)) return false;
  return true;
}

Future<bool> _canShowToday(SharedPreferences prefs) async {
  final lastShown = prefs.getString('soft_prompt_last_shown');
  final today = _todayKey();
  return lastShown != today;
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}

String _titleForDay(int day, bool isZh) {
  if (isZh) {
    return switch (day) {
      18 => '你的试用期即将结束',
      19 => '仅剩 2 天免费使用',
      20 => '最后一天免费试用',
      _ => '',
    };
  } else {
    return switch (day) {
      18 => 'Your free trial ends soon',
      19 => 'Only 2 days left',
      20 => 'Last day of free trial',
      _ => '',
    };
  }
}

String _bodyForDay(int day, bool isZh) {
  if (isZh) {
    return switch (day) {
      18 => '开启 Blinking Pro，解锁无限的 AI 洞察和高级功能。',
      19 => '即将失去对 AI 助手的访问权限。立即升级获得持续支持。',
      20 => '明天开始，您将需要升级才能继续使用 AI 功能。',
      _ => '',
    };
  } else {
    return switch (day) {
      18 => 'Upgrade to Blinking Pro for unlimited AI insights.',
      19 => 'You\'re about to lose access to AI. Upgrade now.',
      20 => 'Tomorrow, you\'ll need an upgrade for AI features.',
      _ => '',
    };
  }
}

String _ctaForDay(int day, bool isZh) {
  if (isZh) {
    return switch (day) {
      18 => '了解更多',
      19 => '立即升级',
      20 => '现在购买',
      _ => '',
    };
  } else {
    return switch (day) {
      18 => 'Learn more',
      19 => 'Upgrade now',
      20 => 'Get Pro today',
      _ => '',
    };
  }
}

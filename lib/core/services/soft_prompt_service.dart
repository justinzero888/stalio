import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/purchase/paywall_screen.dart';

class SoftPromptService {
  static const _lastShownKey = 'soft_prompt_last_shown';
  static const _reengagePrefix = 'reengage_last_';
  static const _previewStartedKey = 'entitlement_preview_started';

  static Future<int> _previewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final startedStr = prefs.getString(_previewStartedKey);
    if (startedStr == null) return -1;
    final started = DateTime.tryParse(startedStr);
    if (started == null) return -1;
    return DateTime.now().difference(started).inDays + 1;
  }

  static Future<bool> _canShowToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_lastShownKey);
    final today = _todayKey();
    return lastShown != today;
  }

  static Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownKey, _todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<bool> maybeShow(BuildContext context) async {
    final day = await _previewDay();
    if (day < 18 || day > 20) return false;
    if (!await _canShowToday()) return false;

    final isZh = _isZh(context);
    final title = _titleForDay(day, isZh);
    final body = _bodyForDay(day, isZh);
    final cta = _ctaForDay(day, isZh);
    final later = isZh ? '以后再说' : 'Maybe later';

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(later, style: TextStyle(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(cta),
          ),
        ],
      ),
    );

    await _markShown();
    return result ?? false;
  }

  static String _titleForDay(int day, bool isZh) {
    switch (day) {
      case 18:
        return isZh ? '已经三周了！' : "It's been three weeks!";
      case 19:
        return isZh ? 'AI 反思帮到你了吗？' : 'Has AI been helpful?';
      case 20:
        return isZh ? '预览即将结束' : 'Preview ending soon';
      default:
        return '';
    }
  }

  static String _bodyForDay(int day, bool isZh) {
    switch (day) {
      case 18:
        return isZh
            ? '预览还剩 3 天。想继续保持吗？'
            : 'The preview has 3 days left. Want to keep going?';
      case 19:
        return isZh
            ? 'Pro 只需 \$19.99，一次购买，终身使用。'
            : 'Pro is \$19.99 once, and your reflections keep coming.';
      case 20:
        return isZh
            ? '明天预览结束后，新建习惯、AI 和备份将暂停。笔记和已有习惯永久保留。'
            : 'After tomorrow: new habits, AI, and backup pause. Your notes and existing habits stay forever.';
      default:
        return '';
    }
  }

  static String _ctaForDay(int day, bool isZh) {
    switch (day) {
      case 18:
        return isZh ? '了解 Pro' : 'See Pro';
      case 19:
        return isZh ? '获取 Pro' : 'Get Pro';
      case 20:
        return isZh ? '立即获取 Pro' : 'Go Pro now';
      default:
        return '';
    }
  }

  static bool _isZh(BuildContext context) {
    try {
      return Localizations.localeOf(context).languageCode == 'zh';
    } catch (_) {
      return false;
    }
  }

  // ── Re-engagement triggers (RESTRICTED state) ──────────────────────

  static Future<bool> canShowReengage(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastKey = '$_reengagePrefix$triggerKey';
    final lastShown = prefs.getInt(lastKey);
    if (lastShown == null) return true;
    final daysSince = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastShown))
        .inDays;
    return daysSince >= 7;
  }

  static Future<void> markReengageShown(String triggerKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_reengagePrefix$triggerKey',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> showReengage(
    BuildContext context, {
    required String triggerKey,
    required String title,
    required String body,
    String? cta,
  }) async {
    if (!await canShowReengage(triggerKey)) return false;
    if (!context.mounted) return false;

    final isZh = _isZh(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isZh ? '以后再说' : 'Not now',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: Text(cta ?? (isZh ? '获取 Pro — \$19.99' : 'Get Pro — \$19.99')),
          ),
        ],
      ),
    );

    await markReengageShown(triggerKey);

    if (result == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return true;
    }
    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/locale_provider.dart';
import '../purchase/paywall_screen.dart';

class TransitionScreen extends StatelessWidget {
  const TransitionScreen({super.key});

  static const _shownKey = 'transition_screen_shown';

  static Future<bool> hasBeenShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_shownKey) ?? false;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shownKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 32),

              // Header
              Text(
                isZh ? '试用已完成。' : 'Your trial is complete.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // What stays
              _SectionBlock(
                emoji: '✅',
                title: isZh ? '以下功能永久保留' : 'What stays',
                items: [
                  isZh
                      ? '所有笔记，随时添加新笔记'
                      : 'all your notes, with new entries any time',
                  isZh
                      ? '已有习惯，每日打卡'
                      : 'your habits, checked in daily',
                ],
                isZh: isZh,
              ),
              const SizedBox(height: 24),

              // What pauses
              _SectionBlock(
                emoji: '⏸',
                title: isZh ? '以下功能已暂停' : 'What pauses without Pro',
                items: [
                  isZh
                      ? '新建和编辑习惯'
                      : 'new habits and edits',
                  isZh
                      ? 'AI 助手'
                      : 'the AI assistant',
                  isZh
                      ? '跨设备备份与恢复'
                      : 'backup & restore across devices',
                ],
                isZh: isZh,
              ),
              const Spacer(),

              // CTAs
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    await TransitionScreen.markShown();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaywallScreen(),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isZh ? '获取 Pro — \$19.99' : 'Get Pro — \$19.99',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await TransitionScreen.markShown();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    isZh ? '继续使用免费版' : 'Continue free',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String emoji;
  final String title;
  final List<String> items;
  final bool isZh;

  const _SectionBlock({
    required this.emoji,
    required this.title,
    required this.items,
    required this.isZh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.circle,
                          size: 6, color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

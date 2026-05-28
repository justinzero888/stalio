import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/locale_provider.dart';
import '../../providers/ai_persona_provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/purchases_service.dart';
import '../purchase/paywall_screen.dart';

void _onLocaleChanged(BuildContext context) {
  final isZh = context.read<LocaleProvider>().isChinese;
  try { context.read<AiPersonaProvider>().reload(); } catch (_) {}
  try { context.read<StorageService>().reSeedLensesForLocale(isZh); } catch (_) {}
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _completedKey = 'onboarding_completed';

  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _controller.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() async {
    await OnboardingScreen.markCompleted();
    if (mounted) Navigator.pop(context);
  }

  void _finish() async {
    await OnboardingScreen.markCompleted();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _restore() async {
    try {
      final purchases = context.read<PurchasesService>();
      final customerInfo = await purchases.restorePurchases();
      if (customerInfo != null) {
        await OnboardingScreen.markCompleted();
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right, screens 2 & 3 only)
            if (_currentPage >= 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      _isZh ? '跳过' : 'Skip',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ),

            // Page content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: const [
                  _ScreenOne(),
                  _ScreenTwo(),
                  _ScreenThree(),
                ],
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _currentPage == 0
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isZh ? '继续' : 'Continue',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : _currentPage == 1
                      ? Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _skip,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _isZh ? '跳过' : 'Skip',
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _next,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _isZh ? '继续' : 'Continue',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _finish,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isZh ? '开始试用' : 'Start your trial',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _restore,
                              child: Text(
                                _isZh ? '已有 Pro？恢复购买' : 'Already have Pro? Restore',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isZh =>
      context.watch<LocaleProvider>().locale.languageCode == 'zh';
}

// ── Screen 1: Philosophy (no skip) ──────────────────────────────────

class _ScreenOne extends StatelessWidget {
  const _ScreenOne();

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tessera-style gradient art
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                  Colors.purple.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 56),
          Text(
            isZh
                ? '生活由时间的碎片拼成，\n而你选择如何将它们排列。'
                : 'Your life is fragments of time,\nrandomly assembled.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isZh
                ? 'Blinking 是一个安静的角落，\n让你把它们整理成属于自己的故事。'
                : 'Blinking is a quiet place\nto assemble them.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 40),
          // Language toggle
          TextButton.icon(
            onPressed: () async {
              await context.read<LocaleProvider>().toggleLocale();
              _onLocaleChanged(context);
            },
            icon: const Icon(Icons.language, size: 18),
            label: Text(
              isZh ? 'English' : '中文',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen 2: What's inside ────────────────────────────────────────

class _ScreenTwo extends StatelessWidget {
  const _ScreenTwo();

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isZh ? '一切都在「今日」' : 'Everything in "My Day"',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          _FeatureCard(
            emoji: '📅',
            title: isZh ? '统一日历' : 'Unified Calendar',
            description: isZh
                ? '点击日历上的任意日期，查看你的永久历史记录。'
                : 'Tap any date on your weekly calendar to view your permanent history log.',
          ),
          const SizedBox(height: 24),
          _FeatureCard(
            emoji: '📝',
            title: isZh ? '闪烁笔记' : 'Blinking Notes',
            description: isZh
                ? '快速记录每日重点。独特的闪烁提醒，完成前不会消失。'
                : 'Quickly write daily focus notes. They use our signature blinking mechanic to stay unmissable until checked off.',
          ),
          const SizedBox(height: 24),
          _FeatureCard(
            emoji: '🔁',
            title: isZh ? '习惯追踪与总结' : 'Habit Tracking & Summary',
            description: isZh
                ? '每日轻量打卡，开启本地语音提醒，保持生活节奏。'
                : 'Monitor your routines daily and toggle local voice notifications to stay on track.',
          ),
          const SizedBox(height: 36),
          _PrivacyCard(isZh: isZh),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final bool isZh;
  const _PrivacyCard({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF2E7D32), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text('🔒', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isZh
                  ? '100% 私密与离线：你的笔记、习惯和日历历史完全在手机本地处理。零数据追踪、收集或上传到云端。'
                  : '100% Private & Offline: Your notes, habits, and calendar history are processed entirely on your phone. Zero data is tracked, collected, or sent to a cloud server.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Screen 3: The deal ─────────────────────────────────────────────

class _ScreenThree extends StatelessWidget {
  const _ScreenThree();

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isZh ? '开始你的旅程' : 'Start your journey',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('✨', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  isZh ? '全功能试用' : 'Full access trial',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh
                      ? '试用期间全部功能解锁'
                      : 'All features unlocked during trial',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isZh
                ? '你的笔记和习惯永远免费。'
                : 'Your notes and habits stay free forever.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.6,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                isZh
                    ? 'Pro 一次购买 \$19.99，终身解锁全部功能。\n无订阅，永不续费。'
                    : 'Pro is \$19.99 once — unlock everything for life.\nNo subscription, ever.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  height: 1.6,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

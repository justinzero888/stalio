import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_persona_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/llm_config_notifier.dart';
import '../providers/entry_provider.dart';
import '../core/services/entitlement_service.dart';
import '../core/config/constants.dart';
import '../screens/assistant/assistant_screen.dart';
import '../screens/reflection/reflection_session_screen.dart';
import '../screens/purchase/paywall_screen.dart';

class FloatingRobotWidget extends StatefulWidget {
  final int currentTabIndex;
  final void Function(int tabIndex)? onSwitchTab;

  const FloatingRobotWidget({
    super.key,
    required this.currentTabIndex,
    this.onSwitchTab,
  });

  @override
  State<FloatingRobotWidget> createState() => _FloatingRobotWidgetState();
}

class _FloatingRobotWidgetState extends State<FloatingRobotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnimation;

  LlmConfigNotifier? _llmNotifier;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _waveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<LlmConfigNotifier>();
    if (_llmNotifier != notifier) {
      _llmNotifier?.removeListener(_onConfigChanged);
      _llmNotifier = notifier;
      _llmNotifier!.addListener(_onConfigChanged);
    }
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _llmNotifier?.removeListener(_onConfigChanged);
    _bobController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onTap() {
    final entitlement = context.read<EntitlementService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final visual = entitlement.buttonVisual;

    switch (visual) {
      case AIButtonVisual.active:
        _waveController.forward(from: 0);
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => AppConstants.kUseMultiTurnChat
                ? const AssistantScreen()
                : const ReflectionSessionScreen(),
          ),
        );
        break;
      case AIButtonVisual.dormant:
        if (entitlement.isRestricted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        } else {
          final message = isZh
              ? 'AI 功能需升级 Pro。'
              : 'AI features are available with Pro.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }
        break;
      case AIButtonVisual.dormantWarn:
        final message = isZh
            ? '你的 API Key 需要更新。点击前往设置。'
            : 'Your API key needs attention. Tap to go to Settings.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
        widget.onSwitchTab?.call(4);
        break;
      case AIButtonVisual.hidden:
      case AIButtonVisual.pulsing:
        break;
    }
  }

  void _onLongPress() {
    final entitlement = context.read<EntitlementService>();
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 180,
        position.dy - 120,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          height: 24,
          child: Text(
            isZh ? 'AI 助手' : 'AI assistant',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        if (entitlement.currentState == EntitlementState.preview)
          PopupMenuItem(
            enabled: false,
            height: 24,
            child: Text(
              isZh ? '预览 — 剩余 ${entitlement.previewDaysRemaining} 天' : 'Preview — ${entitlement.previewDaysRemaining} ${entitlement.previewDaysRemaining == 1 ? "day" : "days" } left',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (entitlement.currentState == EntitlementState.paid)
          PopupMenuItem(
            enabled: false,
            height: 24,
            child: Text(
              isZh ? 'Pro — 全部功能解锁' : 'Pro — all features unlocked',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        if (entitlement.currentState == EntitlementState.restricted &&
            !entitlement.hasActiveBYOK)
          PopupMenuItem(
            height: 36,
            child: Text(
              isZh ? '获取 Pro — \$19.99 一次购买' : 'Get Pro — \$19.99 once',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentTabIndex >= 4 ||
        widget.currentTabIndex == 2 ||
        widget.currentTabIndex == 3) {
      return const SizedBox.shrink();
    }

    // Content checks: no robot if nothing to reflect on — watch so we rebuild when entries added
    final entryProvider = context.watch<EntryProvider>();
    if (widget.currentTabIndex == 0) {
      // My Day: show only if today has entries
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final hasTodayEntries = entryProvider.entries
          .any((e) => e.createdAt.isAfter(todayStart));
      if (!hasTodayEntries) return const SizedBox.shrink();
    } else if (widget.currentTabIndex == 1) {
      // Moments: show only if any entries exist
      if (entryProvider.entries.isEmpty) return const SizedBox.shrink();
    }

    final entitlement = context.watch<EntitlementService>();
    final visual = entitlement.buttonVisual;
    final canUse = entitlement.canUseAI && visual == AIButtonVisual.active;

    final persona = context.watch<AiPersonaProvider>();
    final avatarPath = persona.avatarPath;
    final avatarFile = avatarPath != null ? File(avatarPath) : null;
    final hasCustomAvatar = avatarFile != null && avatarFile.existsSync();
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final styleAsset = persona.styleAvatarAssetFor(isZh);
    final customEmoji = persona.customStyleEmoji;

    Widget avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: canUse
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasCustomAvatar
          ? ClipOval(child: Image.file(avatarFile, fit: BoxFit.cover))
          : styleAsset != null
              ? ClipOval(child: Image.asset(styleAsset, fit: BoxFit.cover))
              : Center(
                  child: Text(
                    customEmoji ?? '🤖',
                    style: TextStyle(
                        fontSize: 28,
                        color: canUse ? null : Colors.grey[500]),
                  ),
                ),
    );

    final showBadge = visual == AIButtonVisual.dormantWarn;

    final opacity = canUse ? 1.0 : 0.55;
    final animate = canUse;

    Widget robotWidget = Semantics(
      identifier: 'btn_ai_robot',
      child: GestureDetector(
        onTap: _onTap,
        onLongPress: _onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '⚠',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );

    return Positioned(
      right: 16,
      bottom: 90,
      child: Opacity(
        opacity: opacity,
        child: animate
            ? AnimatedBuilder(
                animation: Listenable.merge(
                    [_bobAnimation, _pulseAnimation, _waveAnimation]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bobAnimation.value),
                    child: Transform.rotate(
                      angle: _waveAnimation.value,
                      child: Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: robotWidget,
              )
            : robotWidget,
      ),
    );
  }
}

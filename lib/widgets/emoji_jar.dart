import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jar_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/routine_provider.dart';
import '../core/services/llm_service.dart';
import '../screens/reflection/mood_moment_sheet.dart';

/// A stylised glass jar widget showing emotions as emoji.
///
/// By default loads today's emotions from [JarProvider] via [date].
/// Pass [emotionsOverride] to supply an explicit list instead.
class EmojiJarWidget extends StatelessWidget {
  final DateTime date;
  final double size;
  final List<String>? emotionsOverride;
  final bool canUseAI;
  final bool isToday;
  final List<Map<String, String>> existingReflections;
  final int maxPerDay;
  final VoidCallback? onReflectionSaved;

  const EmojiJarWidget({
    super.key,
    required this.date,
    this.size = 160,
    this.emotionsOverride,
    this.canUseAI = false,
    this.isToday = false,
    this.existingReflections = const [],
    this.maxPerDay = 3,
    this.onReflectionSaved,
  });

  static const int _maxVisible = 30;

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final emotions = emotionsOverride ??
        context.watch<JarProvider>().getDayEmotions(date);

    final int overflowCount =
        emotions.length > _maxVisible ? emotions.length - _maxVisible : 0;
    final List<String> visible = overflowCount > 0
        ? emotions.sublist(0, _maxVisible)
        : emotions;

    // Adaptive font size: shrink when jar is dense
    final double emojiFontSize = visible.length > 15
        ? size * 0.085
        : size * 0.12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            SizedBox(
              width: size,
              height: size * 1.1,
              child: CustomPaint(
                painter: _JarPainter(),
                child: ClipPath(
                  clipper: _JarClipper(),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        size * 0.1, size * 0.18, size * 0.1, size * 0.08),
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              isZh ? '空' : 'empty',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: size * 0.18,
                              ),
                            ),
                          )
                        : _EmojiGrid(
                            emojis: visible,
                            fontSize: emojiFontSize,
                            seed: date.millisecondsSinceEpoch,
                          ),
                  ),
                ),
              ),
            ),
            if (overflowCount > 0)
              Positioned(
                top: size * 0.18,
                right: size * 0.06,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$overflowCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_shouldShowAiButton(emotions)) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            icon: Text(
              existingReflections.isEmpty ? '✨' : '📝',
              style: const TextStyle(fontSize: 14),
            ),
            label: Text(
              existingReflections.isEmpty
                  ? (isZh ? '问问 AI' : 'Ask AI')
                  : (isZh ? '心情反思' : 'Mood Reflection'),
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: () => _openAIBottomSheet(context, emotions, isZh),
          ),
        ],
      ],
    );
  }

  bool _shouldShowAiButton(List<String> emotions) {
    if (!isToday) return existingReflections.isNotEmpty;
    if (!canUseAI) return false;
    if (emotions.isEmpty) return false;
    return true;
  }

  void _openAIBottomSheet(BuildContext context, List<String> emotions, bool isZh) {
    final entryProvider = context.read<EntryProvider>();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));
    final dayEntries = entryProvider.entries
        .where((e) =>
            e.createdAt.isAfter(dateStart) &&
            e.createdAt.isBefore(dateEnd) &&
            !e.tagIds.contains('tag_private'))
        .toList();

    final todayHabits = <String>[];
    try {
      final routineProvider = context.read<RoutineProvider>();
      todayHabits.addAll(
        routineProvider.routines
            .where((r) => r.completionLog
                .any((c) => c.completedAt.isAfter(todayStart)))
            .map((r) => r.name),
      );
    } catch (_) {}

    final moodEmoji = emotions.isNotEmpty ? emotions.first : '😊';
    final moodLabel = _moodLabelForEmoji(moodEmoji, isZh);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodMomentSheet(
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        todayEntries: dayEntries,
        todayHabits: todayHabits,
        existingReflections: existingReflections,
        maxPerDay: maxPerDay,
        selectedDate: date,
        onSaved: onReflectionSaved,
      ),
    );
  }

  String _moodLabelForEmoji(String emoji, bool isZh) {
    switch (emoji) {
      case '😊': return isZh ? '开心' : 'Joyful';
      case '😢': return isZh ? '难过' : 'Sad';
      case '😡': return isZh ? '生气' : 'Angry';
      case '😰': return isZh ? '焦虑' : 'Anxious';
      case '😴': return isZh ? '疲惫' : 'Tired';
      case '🤩': return isZh ? '兴奋' : 'Excited';
      case '😌': return isZh ? '平静' : 'Calm';
      case '😤': return isZh ? '沮丧' : 'Frustrated';
      case '🥰': return isZh ? '爱意' : 'Loving';
      case '😐': return isZh ? '平淡' : 'Neutral';
      default: return emoji;
    }
  }
}

class _AiBottomSheet extends StatefulWidget {
  final List<String> emotions;
  const _AiBottomSheet({required this.emotions});

  @override
  State<_AiBottomSheet> createState() => _AiBottomSheetState();
}

class _AiBottomSheetState extends State<_AiBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _llm = LlmService();
  bool _loading = false;
  String _result = '';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
          _result = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _buildPrompt(int tabIndex) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final emojiStr =
        widget.emotions.isNotEmpty ? widget.emotions.join(' ') : null;
    switch (tabIndex) {
      case 0:
        if (isZh) {
          return emojiStr != null
              ? '我今天的情绪有：$emojiStr。请给我一句温暖的鼓励话语（不超过50字）。'
              : '请给我一句温暖的鼓励话语（不超过50字）。';
        } else {
          return emojiStr != null
              ? 'My mood today: $emojiStr. Give me one warm, encouraging sentence (under 30 words). Respond in English.'
              : 'Give me one warm, encouraging sentence (under 30 words). Respond in English.';
        }
      case 1:
        if (isZh) {
          return emojiStr != null
              ? '我今天的情绪有：$emojiStr。请给我一句创意灵感或思考方向（不超过50字）。'
              : '请给我一句创意灵感或思考方向（不超过50字）。';
        } else {
          return emojiStr != null
              ? 'My mood today: $emojiStr. Give me one creative insight or thought to explore (under 30 words). Respond in English.'
              : 'Give me one creative insight or thought to explore (under 30 words). Respond in English.';
        }
      case 2:
        if (isZh) {
          return emojiStr != null
              ? '我今天的情绪有：$emojiStr。请给我一句增强行动力的动力语句（不超过50字）。'
              : '请给我一句增强行动力的动力语句（不超过50字）。';
        } else {
          return emojiStr != null
              ? 'My mood today: $emojiStr. Give me one motivating sentence to boost action (under 30 words). Respond in English.'
              : 'Give me one motivating sentence to boost action (under 30 words). Respond in English.';
        }
      default:
        return '';
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final text = await _llm.complete(_buildPrompt(_activeTab));
      setState(() => _result = text);
    } catch (e) {
      final isZh = mounted
          ? (context.read<LocaleProvider>().locale.languageCode == 'zh')
          : true;
      final msg = e is LlmException
          ? e.friendlyMessage(isZh)
          : (isZh ? '发生未知错误，请重试。' : 'An unexpected error occurred. Please try again.');
      setState(() => _result = msg);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: isZh ? '鼓励' : 'Encourage'),
                Tab(text: isZh ? '灵感' : 'Inspire'),
                Tab(text: isZh ? '动力' : 'Motivate'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_loading)
                      const Expanded(
                          child: Center(child: CircularProgressIndicator()))
                    else if (_result.isNotEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            _result,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Text(
                            isZh
                                ? '点击下方按钮，让 AI 为你生成'
                                : 'Tap the button below to generate',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _loading ? null : _generate,
                      child: Text(isZh ? '生成' : 'Generate'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays emojis out in a deterministic grid so they never overlap.
/// Cells are arranged left-to-right, top-to-bottom. A seeded random shuffle
/// gives variety while remaining stable for the same [seed] value.
class _EmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final double fontSize;
  final int seed;

  const _EmojiGrid({
    required this.emojis,
    required this.fontSize,
    required this.seed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      // Cell size: give each emoji a square cell based on font size + padding
      final cellSize = fontSize + 4;
      final cols = math.max(1, (w / cellSize).floor());
      final rows = math.max(1, (h / cellSize).floor());
      final maxCells = cols * rows;

      final display =
          emojis.length > maxCells ? emojis.sublist(0, maxCells) : emojis;

      // Build a shuffled list of grid positions using seeded random
      final positions = List.generate(cols * rows, (i) => i)..shuffle(math.Random(seed));
      final usedPositions = positions.sublist(0, display.length);

      return Stack(
        children: List.generate(display.length, (i) {
          final pos = usedPositions[i];
          final col = pos % cols;
          final row = pos ~/ cols;
          final left = col * cellSize + (w - cols * cellSize) / 2;
          final top = row * cellSize;
          return Positioned(
            left: left,
            top: top,
            child: Text(display[i], style: TextStyle(fontSize: fontSize)),
          );
        }),
      );
    });
  }
}

/// Paints a mason jar silhouette with amber tint and shimmer.
class _JarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lid / neck area (top 15% of height)
    final neckTop = h * 0.0;
    final neckBottom = h * 0.15;
    final neckLeft = w * 0.25;
    final neckRight = w * 0.75;

    // Jar body (trapezoid — wider at top, narrower at bottom)
    final bodyTopLeft = w * 0.12;
    final bodyTopRight = w * 0.88;
    final bodyBottom = h * 1.0;
    final bodyBottomLeft = w * 0.18;
    final bodyBottomRight = w * 0.82;
    final bodyTop = neckBottom;

    final jarPath = Path()
      ..moveTo(neckLeft, neckTop)
      ..lineTo(neckRight, neckTop)
      ..lineTo(neckRight, neckBottom)
      ..lineTo(bodyTopRight, bodyTop)
      ..lineTo(bodyBottomRight, bodyBottom)
      ..lineTo(bodyBottomLeft, bodyBottom)
      ..lineTo(bodyTopLeft, bodyTop)
      ..lineTo(neckLeft, neckBottom)
      ..close();

    // Fill: semi-transparent amber
    final fillPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(jarPath, fillPaint);

    // Shimmer overlay (left edge highlight)
    final shimmerRect = Rect.fromLTRB(0, neckTop, w, bodyBottom);
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(shimmerRect);
    canvas.drawPath(jarPath, shimmerPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(jarPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clips the emoji wrap to the jar body shape.
class _JarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final neckBottom = h * 0.15;
    final bodyTopLeft = w * 0.12;
    final bodyTopRight = w * 0.88;
    final bodyBottom = h * 1.0;
    final bodyBottomLeft = w * 0.18;
    final bodyBottomRight = w * 0.82;

    return Path()
      ..moveTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w * 0.75, neckBottom)
      ..lineTo(bodyTopRight, neckBottom)
      ..lineTo(bodyBottomRight, bodyBottom)
      ..lineTo(bodyBottomLeft, bodyBottom)
      ..lineTo(bodyTopLeft, neckBottom)
      ..lineTo(w * 0.25, neckBottom)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

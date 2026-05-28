import 'dart:convert';
import '../../models/entry.dart';
import '../../models/routine.dart';

class PromptContext {
  final List<Entry> entries;
  final String moodSummary;
  final String habitSummary;

  PromptContext({
    required this.entries,
    required this.moodSummary,
    required this.habitSummary,
  });
}

class PromptAssembler {
  static const int _stage1MaxTokens = 3000;
  static const int _stage2MaxTokens = 3000;
  static const int _moodHabitMaxTokens = 200;
  static const int _maxTokensPerStage1Response = 300;
  static const int _maxTokensPerStage2Response = 500;

  static PromptContext buildContext({
    required List<Entry> entries,
    required List<Routine> routines,
    String window = 'auto',
  }) {
    final windowed = _selectContextWindow(entries, window);
    return PromptContext(
      entries: windowed,
      moodSummary: _buildMoodSummary(windowed),
      habitSummary: _buildHabitSummary(routines),
    );
  }

  static String assembleStage1Prompt({
    required List<Entry> entries,
    String moodSummary = '',
    String habitSummary = '',
    required List<String> lenses,
    required String personalityString,
    bool isZh = false,
  }) {
    final notesText = _truncateTokens(
      entries.map((e) => _formatEntry(e, isZh)).join('\n'),
      _stage1MaxTokens,
    );
    final moodText = _truncateTokens(moodSummary, _moodHabitMaxTokens);
    final habitText = _truncateTokens(habitSummary, _moodHabitMaxTokens);

    final lensLines = <String>[];
    for (var i = 0; i < lenses.length; i++) {
      lensLines.add('${i + 1}. ${lenses[i]}');
    }

    return [
      if (isZh) _systemPromptStage1Zh else _systemPromptStage1En,
      '',
      'Voice instruction:',
      '"$personalityString"',
      'Apply within structural constraints — no follow-up questions, no thread.',
      '',
      'The user\'s three lenses:',
      ...lensLines,
      '',
      'Loaded context:',
      notesText,
      moodText,
      habitText,
    ].join('\n');
  }

  static String assembleStage2Prompt({
    required List<Entry> entries,
    String moodSummary = '',
    String habitSummary = '',
    required String lensText,
    required String cardPreview,
    required String personalityString,
    bool isZh = false,
  }) {
    final notesText = _truncateTokens(
      entries.map((e) => _formatEntry(e, isZh)).join('\n'),
      _stage2MaxTokens,
    );
    final moodText = _truncateTokens(moodSummary, _moodHabitMaxTokens);
    final habitText = _truncateTokens(habitSummary, _moodHabitMaxTokens);

    return [
      if (isZh) _systemPromptStage2ZhHeader else _systemPromptStage2EnHeader,
      '',
      'Voice instruction:',
      '"$personalityString"',
      'Apply within structural constraints — no follow-up questions, no thread.',
      '',
      'The user has chosen to read more about this observation:',
      'Lens: "$lensText"',
      'Card preview: "$cardPreview"',
      '',
      'Expand it into 3–6 sentences of observational prose.',
      'Reference actual content from the loaded notes.',
      'Be specific. Never prescriptive. Never generic.',
      'Observe — do not instruct.',
      '',
      'Loaded context:',
      notesText,
      moodText,
      habitText,
    ].join('\n');
  }

  static int maxTokensForStage1() => _maxTokensPerStage1Response;
  static int maxTokensForStage2() => _maxTokensPerStage2Response;

  static const String _systemPromptStage1En = '''
SYSTEM:
You are a thoughtful, grounded companion inside a journaling app.
You have been given the user's recent notes and mood data, plus
the three lenses they use to examine themselves.

TASK — Stage 1:
For each lens, produce one short card text — a single specific line
grounded in the loaded data. The line should be specific enough
that the user recognises something real in it.

If a lens has no honest answer in the data, set 'sparse: true'
and write a brief quiet acknowledgement (e.g. 'Quiet on this one lately.').

Respond ONLY with valid JSON, exactly this shape:
[
  { "lens": 1, "card": "...", "sparse": false },
  { "lens": 2, "card": "...", "sparse": false },
  { "lens": 3, "card": "Quiet on this one lately.", "sparse": true }
]''';

  static const String _systemPromptStage1Zh = '''
SYSTEM:
你是日记应用中的一位深思熟虑、脚踏实地的伙伴。
你获得了用户最近的笔记和心情数据，以及他们用来审视自己的三个镜片。

任务 — 第一阶段：
为每个镜片写一条简短的卡片文本 — 一条具体到加载数据的单一语句。
该语句应足够具体，让用户在其中认出真实的东西。

如果某个镜片在数据中没有诚实的答案，设置 'sparse: true'
并写一句简短的安静致意（例如："这个方面近来安静。"）。

仅以有效 JSON 格式回复，严格按此结构：
[
  { "lens": 1, "card": "...", "sparse": false },
  { "lens": 2, "card": "...", "sparse": false },
  { "lens": 3, "card": "这个方面近来安静。", "sparse": true }
]''';

  static const String _systemPromptStage2EnHeader = '''
SYSTEM:
You are a thoughtful, grounded companion inside a journaling app.''';

  static const String _systemPromptStage2ZhHeader = '''
SYSTEM:
你是日记应用中的一位深思熟虑、脚踏实地的伙伴。''';

  // ── Surface A: Mood Moment ──────────────────────────────────────────

  static int maxTokensForMoodMoment() => 200;

  static String assembleMoodMomentPrompt({
    required String moodEmoji,
    required String moodLabel,
    required String posture,
    required List<Entry> todayEntries,
    required List<String> todayHabits,
    required String personalityString,
    bool isZh = false,
  }) {
    final notesText = todayEntries.isNotEmpty
        ? todayEntries.map((e) => '- ${e.content ?? ''}').join('\n')
        : (isZh ? '(今天暂无笔记)' : '(no notes today)');
    final habitText = todayHabits.isNotEmpty
        ? todayHabits.join(', ')
        : (isZh ? '(今天未完成习惯)' : '(no habits completed today)');

    final postureDef = _postureDefinition(posture, isZh);

    return [
      if (isZh) _systemPromptMoodZh else _systemPromptMoodEn,
      '',
      'Voice instruction:',
      '"$personalityString"',
      'Apply within these constraints — do not change length, add follow-up questions, or hold a thread.',
      '',
      'Posture: $posture',
      postureDef,
      'Today\'s mood: $moodEmoji $moodLabel',
      'Today\'s notes:',
      notesText,
      'Today\'s habits: $habitText',
    ].join('\n');
  }

  static String _postureDefinition(String posture, bool isZh) {
    switch (posture) {
      case 'NOTICE':
        return isZh
            ? '注意到用户此刻的感受。不做评判，不解决问题——只是温柔地注意到。'
            : 'Notice what the user is feeling right now. No judgement, no fixing. Just gently notice.';
      case 'SOFTEN':
        return isZh
            ? '对用户此刻的感受表示温和的关怀。承认情绪的合理性和人性。'
            : 'Offer gentle care for what the user is feeling. Acknowledge the feeling as valid and human.';
      case 'STAY':
        return isZh
            ? '提醒用户停下来与情绪待一会儿。不急着走，不给予安慰——就待在当下。'
            : 'Remind the user to pause and stay with the feeling. No need to rush past it. Just be present.';
      default:
        return '';
    }
  }

  static const String _systemPromptMoodEn = '''
SYSTEM:
You are a warm, grounded companion inside a journaling app.
The user has just logged their mood. Respond in 2-4 sentences,
directly addressing what they recorded. Be specific to their data.
Never generic. Never toxic positivity.
Tone: thoughtful friend, not life coach.''';

  static const String _systemPromptMoodZh = '''
SYSTEM:
你是日记应用中的一位温暖、脚踏实地的伙伴。
用户刚刚记录了他们的心情。用2-4句话回应，
直接回应用户记录的内容。要具体到他们的数据。
不要泛泛而谈。不要虚假的安慰。
语气：体贴的朋友，不是人生导师。''';

  List<Map<String, dynamic>> parseStage1Response(String rawJson) {
    try {
      final decoded = _parseJson(rawJson);
      if (decoded is List) {
        return decoded.map((item) {
          if (item is Map) {
            return {
              'lens': item['lens'] as int? ?? 0,
              'card': item['card'] as String? ?? '',
              'sparse': item['sparse'] as bool? ?? false,
            };
          }
          return {'lens': 0, 'card': '', 'sparse': true};
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  static dynamic _parseJson(String raw) {
    // The LLM may wrap JSON in markdown code blocks — strip those
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline > 0) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }
    return jsonDecode(cleaned.trim());
  }

  static List<Entry> _selectContextWindow(List<Entry> entries, String window) {
    if (entries.isEmpty) return [];
    final sorted = List<Entry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent50 = sorted.take(50).toList();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    switch (window) {
      case 'today':
        return sorted.where((e) => e.createdAt.isAfter(todayStart)).toList();
      case 'recent':
        final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
        return sorted.where((e) => e.createdAt.isAfter(sevenDaysAgo)).toList();
      case 'month':
        final monthStart = DateTime(today.year, today.month, 1);
        return sorted.where((e) => e.createdAt.isAfter(monthStart)).toList();
      case 'last3months': {
        final start = DateTime(today.year, today.month, 1);
        final threeMonthsAgo = DateTime(start.year, start.month - 2, 1);
        return sorted.where((e) => e.createdAt.isAfter(threeMonthsAgo)).toList();
      }
      case 'longer':
        final ninetyDaysAgo = todayStart.subtract(const Duration(days: 90));
        return sorted.where((e) => e.createdAt.isAfter(ninetyDaysAgo)).toList();
      default: // auto
        if (recent50.isEmpty) return [];
        final daysSinceFirst = today.difference(recent50.last.createdAt).inDays;
        final daysSinceLast = today.difference(recent50.first.createdAt).inDays;

        if (daysSinceLast <= 1 && recent50.length >= 7) {
          final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
          return sorted.where((e) => e.createdAt.isAfter(sevenDaysAgo)).toList();
        }
        if (daysSinceLast <= 3 && recent50.length >= 5) {
          final fourteenDaysAgo = todayStart.subtract(const Duration(days: 14));
          return sorted.where((e) => e.createdAt.isAfter(fourteenDaysAgo)).toList();
        }
        if (recent50.length >= 3) {
          final thirtyDaysAgo = todayStart.subtract(const Duration(days: 30));
          return sorted.where((e) => e.createdAt.isAfter(thirtyDaysAgo)).toList();
        }
        return recent50;
    }
  }

  static String _formatEntry(Entry entry, bool isZh) {
    final date = '${entry.createdAt.year}/${entry.createdAt.month.toString().padLeft(2, '0')}/${entry.createdAt.day.toString().padLeft(2, '0')}';
    final emotion = entry.emotion ?? '';
    final content = entry.content ?? '';
    return '[$date $emotion] $content';
  }

  static String _buildMoodSummary(List<Entry> entries) {
    if (entries.isEmpty) return 'No mood data for this period.';
    final emotions = entries
        .where((e) => e.emotion != null && e.emotion!.isNotEmpty)
        .map((e) => e.emotion!)
        .toList();
    if (emotions.isEmpty) return 'No mood data for this period.';
    return 'Moods recorded: ${emotions.join(' ')}';
  }

  static String _buildHabitSummary(List<Routine> routines) {
    if (routines.isEmpty) return 'No habit data for this period.';
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final completed = routines.where((r) {
      final todayLog = r.completionLog
          .where((c) => c.completedAt.isAfter(todayStart));
      return todayLog.isNotEmpty;
    }).map((r) => r.name).toList();
    if (completed.isEmpty) return 'No habits completed today.';
    return 'Habits completed today: ${completed.join(', ')}';
  }

  static String _truncateTokens(String text, int maxTokens) {
    if (text.isEmpty) return '(none)';
    // Rough estimate: 1 token ≈ 4 chars for English, 2 chars for CJK
    var count = 0;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final isCJK = (char.codeUnitAt(0) >= 0x4E00 && char.codeUnitAt(0) <= 0x9FFF) ||
          (char.codeUnitAt(0) >= 0x3400 && char.codeUnitAt(0) <= 0x4DBF) ||
          (char.codeUnitAt(0) >= 0x3000 && char.codeUnitAt(0) <= 0x303F);
      count += isCJK ? 2 : 1;
      if (count > maxTokens * 4) break;
      buffer.write(char);
    }
    return buffer.toString();
  }
  // ── Annual Reflection ───────────────────────────────────────────────

  /// Selects up to 2 representative entries per month from the given year.
  /// Prioritizes entries with emotions and longer content.
  static List<Entry> selectAnnualSamples(List<Entry> allEntries, int year) {
    final monthly = <int, List<Entry>>{};
    for (final e in allEntries) {
      if (e.createdAt.year != year) continue;
      monthly.putIfAbsent(e.createdAt.month, () => []).add(e);
    }

    final samples = <Entry>[];
    for (var month = 1; month <= 12; month++) {
      final entries = monthly[month] ?? [];
      if (entries.isEmpty) continue;

      // Sort by: has emotion first, then by content length
      entries.sort((a, b) {
        final aScore = (a.emotion != null ? 1 : 0) + (a.content.length ?? 0);
        final bScore = (b.emotion != null ? 1 : 0) + (b.content.length ?? 0);
        return bScore.compareTo(aScore);
      });

      samples.addAll(entries.take(2));
    }
    return samples;
  }

  static String assembleAnnualReflectionPrompt({
    required List<Entry> samples,
    required String personalityString,
    required int year,
    bool isZh = false,
  }) {
    final entriesText = samples
        .map((e) => '[${e.createdAt.month}/${e.createdAt.day} ${e.emotion ?? ""}] ${e.content ?? ""}')
        .join('\n');

    return [
      isZh
          ? '你是日记应用中的一位深思熟虑的伙伴。'
          : 'You are a thoughtful companion inside a journaling app.',
      '',
      isZh
          ? '你收到了用户$year年的${samples.length}个代表日记条目。写一份年度反思：'
          : 'You have received ${samples.length} representative journal entries from $year. Write an annual reflection that:',
      '',
      isZh
          ? '1. 找出2-3个贯穿全年的主题'
          : '1. Identifies 2-3 themes that span the year',
      isZh
          ? '2. 注意情绪在不同季节的变化'
          : '2. Notes emotional shifts across seasons',
      isZh
          ? '3. 强调一条个人成长弧线'
          : '3. Highlights one personal growth arc',
      isZh ? '4. 以展望未来作为结尾' : '4. Ends with a forward-looking reflection',
      isZh ? '5. 控制在 8-12 句话以内' : '5. Keep it to 8-12 sentences',
      '',
      'Voice instruction:',
      '"$personalityString"',
      '',
      isZh ? '年度日记样本：' : 'Annual journal samples:',
      entriesText,
    ].join('\n');
  }

  static int maxTokensForAnnual() => 500;
}

class ReflectionCard {
  final int lens;
  final String card;
  final bool sparse;

  ReflectionCard({
    required this.lens,
    required this.card,
    this.sparse = false,
  });

  factory ReflectionCard.fromJson(Map<String, dynamic> json) {
    return ReflectionCard(
      lens: json['lens'] as int? ?? 0,
      card: json['card'] as String? ?? '',
      sparse: json['sparse'] as bool? ?? false,
    );
  }
}

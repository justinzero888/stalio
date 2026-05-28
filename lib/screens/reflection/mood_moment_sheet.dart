import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/entry.dart';
import '../../core/services/llm_service.dart';
import '../../core/services/prompt_assembler.dart';

class MoodMomentSheet extends StatefulWidget {
  final String moodEmoji;
  final String moodLabel;
  final List<Entry> todayEntries;
  final List<String> todayHabits;
  final List<Map<String, String>> existingReflections;
  final int maxPerDay;
  final DateTime selectedDate;
  final VoidCallback? onSaved;

  const MoodMomentSheet({
    super.key,
    required this.moodEmoji,
    required this.moodLabel,
    required this.todayEntries,
    required this.todayHabits,
    this.existingReflections = const [],
    this.maxPerDay = 3,
    required this.selectedDate,
    this.onSaved,
  });

  @override
  State<MoodMomentSheet> createState() => _MoodMomentSheetState();
}

class _MoodMomentSheetState extends State<MoodMomentSheet> {
  final LlmService _llm = LlmService();

  // Local reflections — starts with existing, appends as user generates
  late List<Map<String, String>> _reflections;

  // Per-posture state — tracked independently for each card
  String? _generatingPosture;
  final Map<String, String?> _responses = {};
  final Map<String, String?> _errors = {};

  // Which consumed posture is being viewed (expanded to show text)
  String? _viewingPosture;

  bool get _isZh =>
      context.read<LocaleProvider>().locale.languageCode == 'zh';
  bool get _isToday =>
      _dateKey(widget.selectedDate) == _dateKey(DateTime.now());

  int get _remaining => widget.maxPerDay - _reflections.length;

  @override
  void initState() {
    super.initState();
    _reflections = List.from(widget.existingReflections);
  }

  String _dateKey(DateTime d) =>
      '${d.year}_${d.month}_${d.day}';

  bool _isConsumed(String posture) =>
      _reflections.any((r) => r['posture'] == posture);

  Map<String, String>? _savedFor(String posture) {
    try {
      return _reflections.firstWhere((r) => r['posture'] == posture);
    } catch (_) {
      return null;
    }
  }

  bool _canGenerate() =>
      _isToday && _remaining > 0 && _generatingPosture == null;

  static const _postures = ['NOTICE', 'SOFTEN', 'STAY'];

  String _postureLabel(String posture) {
    switch (posture) {
      case 'NOTICE':
        return _isZh ? '注意' : 'Notice';
      case 'SOFTEN':
        return _isZh ? '关怀' : 'Soften';
      case 'STAY':
        return _isZh ? '停留' : 'Stay';
      default:
        return posture;
    }
  }

  String _postureDesc(String posture) {
    switch (posture) {
      case 'NOTICE':
        return _isZh
            ? '注意到此刻的感受。不评判，只是看见。'
            : 'Notice what you\'re feeling. No judgement, just see it.';
      case 'SOFTEN':
        return _isZh
            ? '对自己温柔一些。承认这些感受都是人之常情。'
            : 'Be gentle with yourself. Your feelings are human.';
      case 'STAY':
        return _isZh
            ? '停一下。不用急着走，就待一会儿。'
            : 'Pause. No need to rush past it. Just stay a moment.';
      default:
        return '';
    }
  }

  IconData _postureIcon(String posture) {
    switch (posture) {
      case 'NOTICE':
        return Icons.visibility;
      case 'SOFTEN':
        return Icons.favorite_border;
      case 'STAY':
        return Icons.self_improvement;
      default:
        return Icons.lightbulb;
    }
  }

  Future<void> _generate(String posture) async {
    if (!_canGenerate()) return;

    setState(() {
      _generatingPosture = posture;
      _responses[posture] = null;
      _errors[posture] = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final personality =
          prefs.getString('ai_assistant_personality') ?? 'Warm and grounded.';

      final prompt = PromptAssembler.assembleMoodMomentPrompt(
        moodEmoji: widget.moodEmoji,
        moodLabel: widget.moodLabel,
        posture: posture,
        todayEntries: widget.todayEntries,
        todayHabits: widget.todayHabits,
        personalityString: personality,
        isZh: _isZh,
      );

      final response = await _llm.complete(
        _isZh ? '请回应。' : 'Respond.',
        systemPrompt: prompt,
        maxTokens: 200,
      );

      if (!mounted) return;
      setState(() {
        _responses[posture] = response;
        _generatingPosture = null;
      });
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[posture] = e.friendlyMessage(_isZh);
        _generatingPosture = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[posture] = _isZh ? '出错了，请重试。' : 'Something went wrong.';
        _generatingPosture = null;
      });
    }
  }

  Future<void> _keepThis(String posture) async {
    final response = _responses[posture];
    if (response == null) return;

    // Save to journal
    final entryProvider = context.read<EntryProvider>();
    try {
      await entryProvider.addEntry(
        type: EntryType.freeform,
        content: '${widget.moodEmoji} ${widget.moodLabel}\n'
            '${_postureLabel(posture)}\n\n$response',
        emotion: widget.moodEmoji,
        tagIds: ['tag_synthesis'],
        mediaUrls: [],
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isZh ? '保存失败。' : 'Failed to save.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final key = 'mood_reflections_${_dateKey(widget.selectedDate)}';
    _reflections.add({'posture': posture, 'text': response});
    await prefs.setString(key, jsonEncode(_reflections));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isZh ? '已保存至日记。' : 'Saved to journal.'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _responses.remove(posture);
      _errors.remove(posture);
    });

    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isZh ? '与此刻共处？' : 'Sit with that?',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text('${widget.moodEmoji} ${widget.moodLabel}',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center),
          if (_isToday)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isZh
                    ? '今日剩余 $_remaining 次'
                    : '$_remaining remaining today',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          for (final posture in _postures)
            _buildPostureCard(theme, posture),
        ],
      ),
    );
  }

  Widget _buildPostureCard(ThemeData theme, String posture) {
    final consumed = _isConsumed(posture);
    final saved = _savedFor(posture);
    final isGenerating = _generatingPosture == posture;
    final canTap = !consumed && _canGenerate() && !isGenerating;
    final isViewing = _viewingPosture == posture;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canTap
              ? () => _generate(posture)
              : consumed
                  ? () => setState(() {
                        _viewingPosture =
                            isViewing ? null : posture;
                      })
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: consumed
                            ? Colors.green.shade100
                            : theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        consumed ? Icons.check : _postureIcon(posture),
                        color: consumed
                            ? Colors.green.shade700
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _postureLabel(posture),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: consumed ? Colors.grey : null,
                            ),
                          ),
                          if (!consumed)
                            Text(_postureDesc(posture),
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13)),
                        ],
                      ),
                    ),
                    if (consumed)
                      Text(
                        _isZh ? '已保存' : 'Saved',
                        style: TextStyle(
                            color: Colors.green.shade700, fontSize: 12),
                      ),
                  ],
                ),
                if (isGenerating)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_responses[posture] != null && isGenerating == false)
                  _buildResponse(theme, posture),
                if (_errors[posture] != null && isGenerating == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off, size: 16, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errors[posture]!,
                              style: TextStyle(
                                  color: Colors.orange[700], fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () => _generate(posture),
                          child: Text(_isZh ? '重试' : 'Retry',
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                // Show saved text when viewing consumed posture
                if (consumed && isViewing && saved != null) ...[
                  const Divider(height: 20),
                  Text(saved['text'] ?? '',
                      style:
                          const TextStyle(fontSize: 14, height: 1.6)),
                ],
                // "Tap to view" hint for consumed
                if (consumed && !isViewing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _isZh ? '点击查看 →' : 'Tap to view →',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponse(ThemeData theme, String posture) {
    final text = _responses[posture];
    if (text == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        Text(text,
            style: const TextStyle(fontSize: 15, height: 1.6)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _keepThis(posture),
            icon: const Icon(Icons.bookmark_add, size: 18),
            label: Text(_isZh ? '保存此条' : 'Keep this'),
          ),
        ),
      ],
    );
  }
}

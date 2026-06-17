import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine.dart';
import '../../models/entry.dart';
import '../../providers/locale_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/tag_provider.dart';

/// ─── Habit Popup Factory ─────────────────────────────────────────────────────
/// Dispatches to the correct popup UI based on the routine's [TrackingUiType].

Future<void> showHabitPopup(BuildContext context, Routine routine, DateTime date) async {
  switch (routine.trackingUiType) {
    case TrackingUiType.boolean:
      await _completeRoutine(context, routine, date);
      return;

    case TrackingUiType.booleanOptionalText:
      await _showBooleanOptionalTextPopup(context, routine, date);
      return;

    case TrackingUiType.duration:
      await _showDurationPopup(context, routine, date);
      return;

    case TrackingUiType.durationOptionalText:
      await _showDurationOptionalTextPopup(context, routine, date);
      return;

    case TrackingUiType.number:
      await _showNumberPopup(context, routine, date);
      return;

    case TrackingUiType.time:
      await _showTimePopup(context, routine, date);
      return;

    case TrackingUiType.scale:
      await _showScalePopup(context, routine, date);
      return;

    case TrackingUiType.scaleOptionalText:
      await _showScaleOptionalTextPopup(context, routine, date);
      return;

    case TrackingUiType.textRequired:
      await _showTextRequiredPopup(context, routine, date);
      return;

    case TrackingUiType.multiTextRequired:
      await _showMultiTextRequiredPopup(context, routine, date);
      return;

    case TrackingUiType.streak:
      await _showStreakPopup(context, routine, date);
      return;
  }
}

// ─── Core Actions ─────────────────────────────────────────────────────────────

Future<void> _completeRoutine(BuildContext context, Routine routine, DateTime date) async {
  await context.read<RoutineProvider>().toggleComplete(routine.id, date: date);
}

void _createEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  final usedTags = tagIds ?? await _resolveHabitTags(context, routine);
  if (content.isNotEmpty) {
    context.read<EntryProvider>().addEntry(
      type: EntryType.routine,
      content: content,
      tagIds: usedTags,
      metadata: {
        'routineId': routine.id,
        'routineName': routine.nameEn,
        'routineDate': date.toIso8601String(),
      },
    );
  }
}

Future<void> _completeWithEntry(BuildContext context, Routine routine, DateTime date, String content, {List<String>? tagIds}) async {
  await _completeRoutine(context, routine, date);
  _createEntry(context, routine, date, content, tagIds: tagIds);
}

Future<List<String>> _resolveHabitTags(BuildContext context, Routine routine) async {
  final tagProvider = context.read<TagProvider>();
  final tags = <String>[];
  final cat = routine.category;

  final catId = _categoryTagId(cat);
  if (catId != null) {
    tags.add(catId);
  }

  final habitTagId = 'habit_${routine.id}';
  if (tagProvider.getTagById(habitTagId) == null) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    await tagProvider.addTag(
      id: habitTagId,
      name: routine.displayName(isZh),
      nameEn: routine.nameEn,
      color: _categoryColor(cat),
      categoryId: catId,
    );
  }
  tags.add(habitTagId);

  return tags;
}

String? _categoryTagId(RoutineCategory? cat) {
  return switch (cat) {
    RoutineCategory.health => 'cat_health',
    RoutineCategory.fitness => 'cat_fitness',
    RoutineCategory.nutrition => 'cat_nutrition',
    RoutineCategory.sleep => 'cat_sleep',
    RoutineCategory.mind => 'cat_mind',
    RoutineCategory.reflection => 'cat_reflection',
    RoutineCategory.restraint => 'cat_restraint',
    RoutineCategory.connection => 'cat_connection',
    RoutineCategory.growth => 'cat_growth',
    RoutineCategory.financial => 'cat_financial',
    RoutineCategory.environment => 'cat_environment',
    _ => 'cat_other',
  };
}

String _categoryColor(RoutineCategory? cat) {
  return switch (cat) {
    RoutineCategory.health => '#34C759',
    RoutineCategory.fitness => '#FF9500',
    RoutineCategory.nutrition => '#FF3B30',
    RoutineCategory.sleep => '#5856D6',
    RoutineCategory.mind => '#AF52DE',
    RoutineCategory.reflection => '#007AFF',
    RoutineCategory.restraint => '#FF2D55',
    RoutineCategory.connection => '#FF6B35',
    RoutineCategory.growth => '#64D2FF',
    RoutineCategory.financial => '#30D158',
    RoutineCategory.environment => '#FFD60A',
    _ => '#9E9E9E',
  };
}

// ─── Boolean Optional Text ────────────────────────────────────────────────────

Future<void> _showBooleanOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  await _completeRoutine(context, routine, date);
  if (!context.mounted) return;
  // Defer to let the RoutineProvider rebuild settle before the ModalBarrier is
  // installed. On iOS, showDialog called mid-rebuild orphans the barrier and
  // freezes all input. Same fix as _showCarryForwardDialog in home_screen.dart.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _BooleanNoteShell(routine: routine, isZh: isZh),
  );
  if (result != null && context.mounted) {
    _createEntry(context, routine, date, result);
  }
}

class _BooleanNoteShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  const _BooleanNoteShell({required this.routine, required this.isZh});
  @override
  State<_BooleanNoteShell> createState() => _BooleanNoteShellState();
}

class _BooleanNoteShellState extends State<_BooleanNoteShell> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;
    return AlertDialog(
      title: _PopupHeader(routine: r, isZh: widget.isZh),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.isZh ? '记录要点...（可选）' : 'Add a note... (optional)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '跳过' : 'Skip')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(widget.isZh ? '保存' : 'Save')),
      ],
    );
  }
}

// ─── Duration ─────────────────────────────────────────────────────────────────

Future<void> _showDurationPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _DurationShell(routine: routine, isZh: isZh, showNote: false),
  );
  if (result != null && context.mounted) {
    final minutes = result['minutes'] as int;
    final note = result['note'] as String? ?? '';
    _completeWithEntry(context, routine, date, note.isNotEmpty ? note : '${minutes}min');
  }
}

Future<void> _showDurationOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _DurationShell(routine: routine, isZh: isZh, showNote: true),
  );
  if (result != null && context.mounted) {
    final minutes = result['minutes'] as int;
    final note = result['note'] as String? ?? '';
    _completeWithEntry(context, routine, date, note.isNotEmpty ? note : '${minutes}min');
  }
}

class _DurationShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  final bool showNote;
  const _DurationShell({required this.routine, required this.isZh, required this.showNote});
  @override
  State<_DurationShell> createState() => _DurationShellState();
}

class _DurationShellState extends State<_DurationShell> {
  final _controller = TextEditingController();
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.routine.trackingTarget ?? widget.routine.trackingMin ?? 5;
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;
    final unit = r.trackingUnit == 'minutes' ? (widget.isZh ? '分钟' : 'min') : (widget.isZh ? '次' : '');
    return AlertDialog(
      title: _PopupHeader(routine: r, isZh: widget.isZh),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.isZh ? '多长时间？' : 'How long?', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _value = (_value - (r.trackingIncrement ?? 1)).clamp(
                    (r.trackingMin ?? 1).toDouble(),
                    (r.trackingMax ?? 120).toDouble(),
                  );
                }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${_value.toInt()} $unit', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                onPressed: () => setState(() {
                  _value = (_value + (r.trackingIncrement ?? 1)).clamp(
                    (r.trackingMin ?? 1).toDouble(),
                    (r.trackingMax ?? 120).toDouble(),
                  );
                }),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (widget.showNote) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.isZh ? '补充说明...（可选）' : 'Add a note... (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '取消' : 'Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {'minutes': _value.toInt(), 'note': _controller.text.trim()}),
          child: Text(widget.isZh ? '保存并完成' : 'Save & Done'),
        ),
      ],
    );
  }
}

// ─── Number ───────────────────────────────────────────────────────────────────

Future<void> _showNumberPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _NumberShell(routine: routine, isZh: isZh),
  );
  if (result != null && context.mounted) {
    final value = result['value'] as int;
    _completeWithEntry(context, routine, date, '$value ${routine.trackingUnit ?? ''}');
  }
}

class _NumberShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  const _NumberShell({required this.routine, required this.isZh});
  @override
  State<_NumberShell> createState() => _NumberShellState();
}

class _NumberShellState extends State<_NumberShell> {
  final _controller = TextEditingController();
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = (widget.routine.trackingTarget ?? widget.routine.trackingMin ?? 0).toDouble();
    _controller.text = _value.toInt().toString();
  }

  void _updateValue(double newValue) {
    setState(() {
      _value = newValue;
      _controller.text = newValue.toInt().toString();
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;
    final unit = r.trackingUnit ?? '';
    final inc = (r.trackingIncrement ?? 1).toDouble();
    return AlertDialog(
      title: _PopupHeader(routine: r, isZh: widget.isZh, subtitle: r.twoMinVersionEn),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => _updateValue((_value - inc).clamp((r.trackingMin ?? 0).toDouble(), (r.trackingMax ?? 99999).toDouble())), icon: const Icon(Icons.remove_circle_outline)),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (v) { final n = int.tryParse(v); if (n != null) _value = n.toDouble(); },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _updateValue((_value + inc).clamp((r.trackingMin ?? 0).toDouble(), (r.trackingMax ?? 99999).toDouble())), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          const SizedBox(height: 4),
          Text(unit, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '取消' : 'Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, {'value': _value.toInt()}),
          child: Text(widget.isZh ? '保存并完成' : 'Save & Done'),
        ),
      ],
    );
  }
}

// ─── Time ─────────────────────────────────────────────────────────────────────

Future<void> _showTimePopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final now = TimeOfDay.now();
  final result = await showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => _TimePickerShell(routine: routine, isZh: isZh, initial: now),
  );
  if (result != null && context.mounted) {
    final t = result.format(context);
    _completeWithEntry(context, routine, date, t);
  }
}

class _TimePickerShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  final TimeOfDay initial;
  const _TimePickerShell({required this.routine, required this.isZh, required this.initial});
  @override
  State<_TimePickerShell> createState() => _TimePickerShellState();
}

class _TimePickerShellState extends State<_TimePickerShell> {
  late TimeOfDay _time;

  @override
  void initState() { super.initState(); _time = widget.initial; }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _PopupHeader(routine: widget.routine, isZh: widget.isZh),
      content: SizedBox(
        height: 200,
        child: Center(
          child: GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
            child: Text(
              _time.format(context),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 40),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '取消' : 'Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _time), child: Text(widget.isZh ? '保存并完成' : 'Save & Done')),
      ],
    );
  }
}

// ─── Scale ────────────────────────────────────────────────────────────────────

Future<void> _showScalePopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<int?>(
    context: context,
    builder: (ctx) => _ScaleShell(routine: routine, isZh: isZh, showNote: false),
  );
  if (result != null && context.mounted) {
    _completeWithEntry(context, routine, date, 'Rating: $result/5');
  }
}

Future<void> _showScaleOptionalTextPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _ScaleShell(routine: routine, isZh: isZh, showNote: true),
  );
  if (result != null && context.mounted) {
    final rating = result['rating'] as int;
    final note = result['note'] as String? ?? '';
    _completeWithEntry(context, routine, date, note.isNotEmpty ? '$note ($rating/5)' : 'Rating: $rating/5');
  }
}

class _ScaleShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  final bool showNote;
  const _ScaleShell({required this.routine, required this.isZh, required this.showNote});
  @override
  State<_ScaleShell> createState() => _ScaleShellState();
}

class _ScaleShellState extends State<_ScaleShell> {
  int? _selected;
  final _controller = TextEditingController();
  static const _emoji = ['😫', '😕', '😐', '🙂', '😊'];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _PopupHeader(routine: widget.routine, isZh: widget.isZh),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _selected = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _selected == i + 1 ? 1.0 : 0.4,
                        child: Text(_emoji[i], style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 2),
                      Text('${i + 1}', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
                    ],
                  ),
                ),
              )),
            ),
          ),
          if (widget.showNote) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: widget.isZh ? '补充说明...（可选）' : 'Add a note... (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '取消' : 'Cancel')),
        FilledButton(
          onPressed: _selected == null ? null : () => widget.showNote
              ? Navigator.pop(context, {'rating': _selected!, 'note': _controller.text.trim()})
              : Navigator.pop(context, _selected),
          child: Text(widget.isZh ? '保存并完成' : 'Save & Done'),
        ),
      ],
    );
  }
}

// ─── Text Required ────────────────────────────────────────────────────────────

Future<void> _showTextRequiredPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _TextRequiredShell(routine: routine, isZh: isZh, fieldCount: 1),
  );
  if (result != null && context.mounted) {
    final content = (result['content'] as String?)?.trim() ?? '';
    final customTags = (result['tags'] as String?)?.trim();
    final fullContent = customTags != null && customTags.isNotEmpty
        ? '$content\n\n#${customTags.split(',').map((t) => t.trim()).join(' #')}'
        : content;
    if (fullContent.isNotEmpty) {
      _completeWithEntry(context, routine, date, fullContent);
    }
  }
}

Future<void> _showMultiTextRequiredPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => _TextRequiredShell(routine: routine, isZh: isZh, fieldCount: 3),
  );
  if (result != null && context.mounted) {
    final content = (result['content'] as String?)?.trim() ?? '';
    final customTags = (result['tags'] as String?)?.trim();
    final fullContent = customTags != null && customTags.isNotEmpty
        ? '$content\n\n#${customTags.split(',').map((t) => t.trim()).join(' #')}'
        : content;
    if (fullContent.isNotEmpty) {
      _completeWithEntry(context, routine, date, fullContent);
    }
  }
}

class _TextRequiredShell extends StatefulWidget {
  final Routine routine;
  final bool isZh;
  final int fieldCount;
  const _TextRequiredShell({required this.routine, required this.isZh, required this.fieldCount});
  @override
  State<_TextRequiredShell> createState() => _TextRequiredShellState();
}

class _TextRequiredShellState extends State<_TextRequiredShell> {
  final _controllers = <TextEditingController>[];
  final _tagController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.fieldCount; i++) {
      final c = TextEditingController();
      c.addListener(_checkHasText);
      _controllers.add(c);
    }
  }

  void _checkHasText() {
    final has = _controllers.any((c) => c.text.trim().isNotEmpty);
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    _tagController.dispose();
    super.dispose();
  }

  String get _combinedText {
    final parts = _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty);
    if (widget.fieldCount == 1) return parts.firstOrNull ?? '';
    return parts.toList().asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;
    return AlertDialog(
      title: _PopupHeader(routine: r, isZh: widget.isZh, subtitle: r.twoMinVersionEn),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(widget.fieldCount, (i) => Padding(
            padding: EdgeInsets.only(bottom: i < widget.fieldCount - 1 ? 8 : 0),
            child: TextField(
              controller: _controllers[i],
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.isZh ? '写下你的想法...' : 'Write your thoughts...',
                labelText: widget.fieldCount > 1 ? '${i + 1}.' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )),
          const SizedBox(height: 10),
          TextField(
            controller: _tagController,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: widget.isZh ? '自定义标签 (逗号分隔)' : 'Custom tags (comma separated)',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.isZh ? '跳过' : 'Skip')),
        FilledButton(
          onPressed: _hasText ? () => Navigator.pop(context, {'content': _combinedText, 'tags': _tagController.text}) : null,
          child: Text(widget.isZh ? '保存并完成' : 'Save & Done'),
        ),
      ],
    );
  }
}

// ─── Streak ───────────────────────────────────────────────────────────────────

Future<void> _showStreakPopup(BuildContext context, Routine routine, DateTime date) async {
  final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: _PopupHeader(routine: routine, isZh: isZh),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isZh ? '今天做到了吗？' : 'Did you stay on track today?',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(isZh ? '✅ 做到了' : '✅ YES'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade400, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(isZh ? '❌ 没做到' : '❌ NO'),
                ),
              ),
            ],
          ),
          if (routine.streak > 0) ...[
            const SizedBox(height: 12),
            Text('🔥 ${isZh ? '当前连续' : 'Current streak'}: ${routine.streak} ${isZh ? '天' : 'days'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
          ],
        ],
      ),
    ),
  );
  if (result == true && context.mounted) {
    await _completeRoutine(context, routine, date);
  }
}

// ─── Shared Popup Header ──────────────────────────────────────────────────────

class _PopupHeader extends StatelessWidget {
  final Routine routine;
  final bool isZh;
  final String? subtitle;
  const _PopupHeader({required this.routine, required this.isZh, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final icon = routine.icon ?? routine.effectiveIcon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(child: Text(routine.displayName(isZh), style: const TextStyle(fontSize: 18))),
        ]),
        if (routine.streak > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('🔥 ${isZh ? '连续' : 'Streak'}: ${routine.streak} ${isZh ? '天' : 'days'}',
                style: TextStyle(color: Colors.orange[700], fontSize: 13)),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(140), fontSize: 13)),
          ),
      ],
    );
  }
}

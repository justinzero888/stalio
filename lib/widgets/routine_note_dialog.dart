import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../models/entry.dart';
import '../providers/locale_provider.dart';
import '../providers/entry_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/tag_provider.dart';

class RoutineNoteDialog extends StatefulWidget {
  final Routine routine;
  final DateTime date;

  const RoutineNoteDialog({
    super.key,
    required this.routine,
    required this.date,
  });

  bool get _isWritingHabit =>
      routine.category == RoutineCategory.reflection ||
      routine.category == RoutineCategory.mindfulness;

  @override
  State<RoutineNoteDialog> createState() => _RoutineNoteDialogState();
}

class _RoutineNoteDialogState extends State<RoutineNoteDialog> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  bool _hasText = false;

  bool get _isWritingHabit => widget._isWritingHabit;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (_isWritingHabit && text.isEmpty) return;

    final entryProvider = context.read<EntryProvider>();
    entryProvider.addEntry(
      type: EntryType.routine,
      content: text,
      tagIds: _resolveHabitTags(),
    );

    context.read<RoutineProvider>().toggleComplete(widget.routine.id, date: widget.date);
    Navigator.of(context).pop();
  }

  List<String> _resolveHabitTags() {
    final tagProvider = context.read<TagProvider>();
    final tags = <String>[];
    final catIds = _categoryTagIds();
    for (final id in catIds) {
      if (tagProvider.getTagById(id) != null) tags.add(id);
    }
    return tags;
  }

  List<String> _categoryTagIds() {
    final cat = widget.routine.category;
    return switch (cat) {
      RoutineCategory.health => ['cat_health'],
      RoutineCategory.fitness => ['cat_fitness'],
      RoutineCategory.nutrition => ['cat_nutrition'],
      RoutineCategory.sleep => ['cat_sleep'],
      RoutineCategory.mindfulness => ['cat_mindfulness'],
      RoutineCategory.reflection => ['cat_reflection'],
      RoutineCategory.restraint => ['cat_restraint'],
      RoutineCategory.connection => ['cat_connection'],
      RoutineCategory.other => ['cat_other'],
      _ => [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final r = widget.routine;
    final icon = r.icon ?? r.effectiveIcon;

    return AlertDialog(
      title: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Expanded(child: Text(r.displayName(isZh), style: const TextStyle(fontSize: 18))),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.streak > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('🔥 ${isZh ? '连续' : 'Streak'}: ${r.streak} ${isZh ? '天' : 'days'}',
                  style: TextStyle(color: Colors.orange[700], fontSize: 14)),
            ),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: _isExpanded ? 5 : 3,
            decoration: InputDecoration(
              hintText: _isWritingHabit
                  ? (isZh ? '写下你的想法...' : 'Write your thoughts...')
                  : (isZh ? '记点什么...（可选）' : 'Add a note... (optional)'),
              border: const OutlineInputBorder(),
            ),
          ),
          if (!_isWritingHabit && _controller.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded
                      ? (isZh ? '收起' : 'Collapse')
                      : (isZh ? '展开更多' : 'Expand'),
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isZh ? '跳过' : 'Skip'),
        ),
        FilledButton(
          onPressed: _isWritingHabit && !_hasText ? null : _submit,
          child: Text(isZh ? '保存并完成' : 'Save & Done'),
        ),
      ],
    );
  }
}

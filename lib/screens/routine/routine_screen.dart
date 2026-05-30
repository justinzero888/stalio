import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/file_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/routine_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/entry_provider.dart';
import '../../models/routine.dart';

/// Renders a routine's icon: custom image if set, else emoji fallback.
Widget _buildRoutineIcon(Routine routine, {double size = 20}) {
  if (routine.iconImagePath != null) {
    final file = File(routine.iconImagePath!);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(file,
            width: size, height: size, fit: BoxFit.cover),
      );
    }
  }
  return Text(routine.effectiveIcon, style: TextStyle(fontSize: size));
}

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => RoutineScreenState();
}

class RoutineScreenState extends State<RoutineScreen> {
  final Set<String> _manuallyAddedToday = {};

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final provider = context.watch<RoutineProvider>();
    final activeRoutines = provider.routines.where((r) => r.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '习惯' : 'Habits'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCards(provider: provider),
          const SizedBox(height: 20),
          _TodaySection(
            manuallyAdded: _manuallyAddedToday,
            onManualAdd: (id) => setState(() => _manuallyAddedToday.add(id)),
          ),
          const SizedBox(height: 24),
          if (activeRoutines.isNotEmpty) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZh ? '连续记录' : 'Streak Matrix',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _StreakMatrix(routines: activeRoutines),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void showAddRoutineDialog(BuildContext context) {
    RoutineDialog.show(context, existing: null);
  }
}

// ── Summary Cards ────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final RoutineProvider provider;
  const _SummaryCards({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final activeHabits = provider.routines.where((r) => r.isActive).toList();
    int bestStreak = 0;
    for (final r in activeHabits) {
      if (r.streak > bestStreak) bestStreak = r.streak;
    }

    return Row(
      children: [
        _StatCard(
          icon: Icons.checklist,
          value: '${provider.routines.length}',
          label: isZh ? '总计' : 'Total',
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.local_fire_department,
          value: '$bestStreak${isZh ? "天" : "d"}',
          label: isZh ? '最佳连续' : 'Best Streak',
          color: Colors.amber.shade700,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.play_circle,
          value: '${activeHabits.length}',
          label: isZh ? '活跃' : 'Active',
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2 — 执行 / Do
// ─────────────────────────────────────────────
class _TodaySection extends StatefulWidget {
  final Set<String> manuallyAdded;
  final void Function(String id) onManualAdd;

  const _TodaySection({required this.manuallyAdded, required this.onManualAdd});

  @override
  State<_TodaySection> createState() => _TodaySectionState();
}

class _TodaySectionState extends State<_TodaySection> {
  final Set<String> _recentlyCompleted = {};
  final int _lastBestStreakShown = 0;

  void _onRoutineToggle(BuildContext context, Routine routine, bool wasCompleted) {
    final provider = context.read<RoutineProvider>();
    if (wasCompleted) {
      provider.unmarkRoutine(routine.id);
    } else {
      provider.completeRoutine(routine.id);
      HapticFeedback.lightImpact();
      setState(() => _recentlyCompleted.add(routine.id));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _recentlyCompleted.remove(routine.id));
      });
    }
  }

  String _greeting(bool isZh) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isZh ? '早上好，今天是你的新一天。' : 'Good morning. Here\'s your day.';
    if (hour < 18) return isZh ? '下午了，继续加油。' : 'Afternoon check-in. Keep going.';
    return isZh ? '快结束了，你做得很好。' : 'Almost done for the day.';
  }

  int _noteEarnedGrace(Routine routine) {
    final entries = context.read<EntryProvider>().allEntries;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var extraDays = 0;
    for (var d = 1; d <= 3; d++) {
      final checkDate = todayDate.subtract(Duration(days: d));
      if (routine.isCompletedOn(checkDate)) break;
      final hasNote = entries.any((e) =>
          e.createdAt.year == checkDate.year &&
          e.createdAt.month == checkDate.month &&
          e.createdAt.day == checkDate.day);
      if (hasNote) extraDays++;
    }
    return extraDays.clamp(0, 2);
  }

  Widget _buildGraceBanner(
      BuildContext context, Routine routine, bool isZh, ThemeData theme) {
    final noteDays = _noteEarnedGrace(routine);
    final total = 1 + noteDays;
    final missed = routine.consecutiveMissedDays;
    final left = total - missed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: left > 1 ? Colors.teal.withValues(alpha: 0.08) : Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16,
                color: left > 1 ? Colors.teal[400] : Colors.orange[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                noteDays > 0
                    ? (isZh
                        ? '${routine.displayName(isZh)} — 笔记延长了保护期 ($left 天剩余)'
                        : '${routine.displayName(isZh)} — note extended grace ($left day${left > 1 ? "s" : ""} left)')
                    : (isZh
                        ? '${routine.displayName(isZh)} — 今天完成仍可保持连续记录'
                        : '${routine.displayName(isZh)} — still time to keep your streak'),
                style: TextStyle(
                  color: left > 1 ? Colors.teal[600] : Colors.orange[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final provider = context.watch<RoutineProvider>();
    final theme = Theme.of(context);
    final today = DateTime.now();

    final scheduled = provider.getRoutinesForDate(today);
    final adhocAdded = provider.adhocRoutines
        .where((r) => widget.manuallyAdded.contains(r.id))
        .toList();
    // Deduplicate — a routine might appear in both lists
    final seen = <String>{};
    final allToday = <Routine>[];
    for (final r in [...scheduled, ...adhocAdded]) {
      if (seen.add(r.id)) allToday.add(r);
    }

    final pending = allToday.where((r) => !r.isCompletedToday).toList();
    final completed = allToday.where((r) => r.isCompletedToday).toList();
    final total = allToday.length;
    final done = completed.length;
    final allDone = total > 0 && done == total;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Date header
        Text(
          DateFormat(isZh ? 'M月d日 EEEE' : 'EEEE, MMMM d').format(today),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        // Progress header
        if (total > 0) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: done / total,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                allDone
                    ? '✓'
                    : '$done / $total',
                style: TextStyle(
                  color: allDone ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Motivational copy
        if (!allDone)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _greeting(isZh),
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isZh ? '全部完成，做得漂亮。' : 'All done today. Well done.',
              style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        const SizedBox(height: 4),

        // Grace reminders — note-earned extension
        if (!allDone) ...[
          for (final r in pending.where((r) => r.inGrace))
            _buildGraceBanner(context, r, isZh, theme),
        ],

        // Personal best streak banner
        if (allDone) ...[
          for (final r in completed.where((r) => r.streak > 1 && r.streak % 7 == 0))
            if (r.streak > _lastBestStreakShown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isZh
                              ? '${r.displayName(isZh)} — 新纪录！连续 ${r.streak} 天'
                              : '${r.displayName(isZh)} — New best! ${r.streak} day streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],

        // Pending section
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isZh ? '待完成' : 'Still to do',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pending.length}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...pending.map((r) => _DoRoutineTile(
                routine: r,
                isCompleted: false,
                isFlashing: _recentlyCompleted.contains(r.id),
                onToggle: () => _onRoutineToggle(context, r, false),
              )),
          const SizedBox(height: 16),
        ],

        // Completed section
        if (completed.isNotEmpty) ...[
          Text(
            isZh ? '已完成' : 'Done today',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...completed.map((r) => _DoRoutineTile(
                routine: r,
                isCompleted: true,
                isFlashing: _recentlyCompleted.contains(r.id),
                onToggle: () => _onRoutineToggle(context, r, true),
              )),
          const SizedBox(height: 16),
        ],

        if (allToday.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  isZh ? '今日无安排' : 'Nothing scheduled today',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isZh
                      ? '去"建造"添加一个习惯吧'
                      : 'Add a habit in Build',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),

        _ManualAddButton(
          manuallyAdded: widget.manuallyAdded,
          onAdd: widget.onManualAdd,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _DoRoutineTile extends StatelessWidget {
  final Routine routine;
  final bool isCompleted;
  final bool isFlashing;
  final VoidCallback onToggle;

  const _DoRoutineTile({
    required this.routine,
    required this.isCompleted,
    required this.isFlashing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isFlashing ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isCompleted ? Colors.grey[50] : null,
        elevation: isCompleted ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCompleted
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.grey[200]!
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                      : Icon(Icons.circle_outlined,
                          color: theme.colorScheme.primary.withValues(alpha: 0.4), size: 22),
                ),
              ),
              const SizedBox(width: 10),
              _buildRoutineIcon(routine, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.displayName(isZh),
                      style: TextStyle(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey[400] : null,
                        fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (routine.reminderTime != null)
                      Text(
                        routine.reminderTime!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualAddButton extends StatelessWidget {
  final Set<String> manuallyAdded;
  final void Function(String) onAdd;
  const _ManualAddButton({required this.manuallyAdded, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final adhoc = context.read<RoutineProvider>().adhocRoutines;
    if (adhoc.isEmpty) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () {
        _showPicker(context, adhoc);
      },
      icon: const Icon(Icons.add),
      label: Text(isZh ? '手动加入' : 'Add'),
    );
  }

  void _showPicker(BuildContext context, List<Routine> adhoc) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          Text(isZh ? '选择临时习惯' : 'Select Ad-hoc Routine',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...adhoc.map((r) => ListTile(
                leading: _buildRoutineIcon(r, size: 22),
                title: Text(r.displayName(isZh)),
                trailing: manuallyAdded.contains(r.id)
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  onAdd(r.id);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

class _StreakMatrix extends StatelessWidget {
  final List<Routine> routines;

  const _StreakMatrix({required this.routines});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (routines.isEmpty) return const SizedBox.shrink();

    DateTime earliest = today;
    bool hasData = false;
    for (final r in routines) {
      if (r.completionLog.isNotEmpty) {
        hasData = true;
        for (final c in r.completionLog) {
          final d = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day);
          if (d.isBefore(earliest)) earliest = d;
        }
      }
      final rDate = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      if (rDate.isBefore(earliest)) earliest = rDate;
    }

    if (!hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isZh ? '暂无完成记录。开始执行你的习惯吧！' : 'No completions yet. Start doing your habits!',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    while (earliest.weekday != DateTime.sunday) {
      earliest = earliest.subtract(const Duration(days: 1));
    }

    final weeks = <List<DateTime>>[];
    var cursor = earliest;
    while (cursor.isBefore(today) || cursor == today) {
      final week = List.generate(
        7, (d) => DateTime(cursor.year, cursor.month, cursor.day).add(Duration(days: d)));
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    while (cursor.isBefore(today) || cursor == today) {
      final week = List.generate(
        7, (d) => DateTime(cursor.year, cursor.month, cursor.day).add(Duration(days: d)));
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    final months = <int, int>{};
    for (int w = 0; w < weeks.length; w++) {
      final month = weeks[w].first.month;
      months.putIfAbsent(month, () => w);
    }

    const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const dayLabels = ['', 'M', '', 'W', '', 'F', ''];
    const cellSize = 14.0;
    const gap = 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 120),
                  ...months.entries.map((e) => Padding(
                    padding: EdgeInsets.only(left: e.key == 0 ? 0 : (cellSize + gap) * (e.value)),
                    child: Text(monthNames[e.key], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  )),
                ],
              ),
              const SizedBox(height: 4),
              ...routines.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Text(r.effectiveIcon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              r.displayName(isZh),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...weeks.map((week) {
                      return Row(
                        children: week.map((d) {
                          final completed = r.isCompletedOn(d);
                          final isFuture = d.isAfter(today);
                          return Container(
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? Colors.transparent
                                  : completed
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              )),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 120),
                  ...List.generate(7, (i) => SizedBox(
                    width: cellSize + gap,
                    child: dayLabels[i].isNotEmpty
                        ? Center(child: Text(dayLabels[i], style: const TextStyle(fontSize: 8, color: Colors.grey)))
                        : const SizedBox.shrink(),
                  )),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(1))),
            const SizedBox(width: 4),
            Text(isZh ? '未完成' : 'Missed', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 16),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(1))),
            const SizedBox(width: 4),
            Text(isZh ? '已完成' : 'Done', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

// Add / Edit dialog
// ─────────────────────────────────────────────
class RoutineDialog {
  static void show(BuildContext context, {Routine? existing}) {
    showDialog(
      context: context,
      builder: (_) => _RoutineDialogWidget(existing: existing),
    );
  }
}

class _RoutineDialogWidget extends StatefulWidget {
  final Routine? existing;
  const _RoutineDialogWidget({this.existing});

  @override
  State<_RoutineDialogWidget> createState() => _RoutineDialogWidgetState();
}

class _RoutineDialogWidgetState extends State<_RoutineDialogWidget> {
  late TextEditingController _nameController;
  late TextEditingController _reminderController;
  late TextEditingController _whyController;
  late RoutineFrequency _frequency;
  late List<int> _selectedDays; // for weekly
  DateTime? _scheduledDate;     // for scheduled
  RoutineCategory? _category;
  String? _iconImagePath;
  bool _isActive = true;
  bool _voiceEnabled = false;

  static const List<String> _dayLabelsZh = ['', '一', '二', '三', '四', '五', '六', '日'];
  static const List<String> _dayLabelsEn = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    _nameController = TextEditingController(text: r?.displayName(isZh) ?? '');
    _reminderController = TextEditingController(text: r?.reminderTime ?? '');
    _whyController = TextEditingController(
      text: isZh ? (r?.description ?? '') : (r?.descriptionEn ?? r?.description ?? ''));
    _frequency = r?.frequency ?? RoutineFrequency.daily;
    _selectedDays = List<int>.from(r?.scheduledDaysOfWeek ?? []);
    _scheduledDate = r?.scheduledDate;
    _category = r?.category;
    _iconImagePath = r?.iconImagePath;
    _isActive = r?.isActive ?? true;
    _voiceEnabled = r?.voiceEnabled ?? false;
    _reminderController.addListener(_onReminderChanged);
  }

  void _onReminderChanged() {
    setState(() {}); // Show/hide voice toggle dynamically as user types
  }

  @override
  void dispose() {
    _reminderController.removeListener(_onReminderChanged);
    _nameController.dispose();
    _reminderController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? (isZh ? '编辑习惯' : 'Edit Routine') : (isZh ? '添加习惯' : 'Add Routine')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon picker
            Center(
              child: GestureDetector(
                onTap: _pickIcon,
                onLongPress: () => setState(() => _iconImagePath = null),
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _iconImagePath != null &&
                              File(_iconImagePath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_iconImagePath!),
                                  fit: BoxFit.cover),
                            )
                          : Center(
                              child: Text(
                                widget.existing?.effectiveIcon ?? '⭐',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            MergeSemantics(child: Semantics(
              identifier: 'input_routine_name',
              textField: true,
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isZh ? '名称' : 'Name',
                  hintText: isZh ? '例如: 喝水' : 'e.g. Drink water',
                ),
              ),
            )),
            const SizedBox(height: 12),

            // Why — personal motivation
            TextField(
              controller: _whyController,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: isZh ? '为什么重要？' : 'Why does this matter?',
                hintText: isZh
                    ? '写下你的原因 — 它会帮你坚持下去'
                    : 'Add your reason — it helps you stick to it',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // Reminder
            MergeSemantics(child: Semantics(
              identifier: 'input_routine_reminder',
              child: TextField(
                controller: _reminderController,
                keyboardType: TextInputType.datetime,
                maxLength: 5,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                ],
                decoration: InputDecoration(
                  labelText: isZh ? '提醒时间 (可选)' : 'Reminder (optional)',
                  hintText: '08:00',
                  helperText: isZh ? '24小时格式，仅本地提醒' : '24-hour format, local only',
                  counterText: '',
                ),
              ),
            )),
            const SizedBox(height: 4),
            // Voice toggle — only shown when global voice is enabled
            if (_reminderController.text.trim().isNotEmpty) ...[
              FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  final prefs = snapshot.data;
                  final globalVoice = prefs?.getBool('voice_notifications_enabled') ?? false;
                  if (!globalVoice) return const SizedBox.shrink();
                  return MergeSemantics(child: Semantics(
                    identifier: 'toggle_speak_reminder',
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isZh ? '朗读提醒' : 'Speak reminder',
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(isZh ? '提醒时如果应用打开，会朗读习惯名称' : 'Reads the routine aloud at reminder time when app is open',
                          style: const TextStyle(fontSize: 12)),
                      value: _voiceEnabled,
                      onChanged: (v) => setState(() => _voiceEnabled = v),
                    ),
                  ));
                },
              ),
            ],
            const SizedBox(height: 12),

            // Frequency
            Text(isZh ? '频率' : 'Frequency',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButton<RoutineFrequency>(
              value: _frequency,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                    value: RoutineFrequency.daily,
                    child: Text(isZh ? '每天' : 'Daily')),
                DropdownMenuItem(
                    value: RoutineFrequency.weekly,
                    child: Text(isZh ? '每周 (指定星期)' : 'Weekly (select days)')),
                DropdownMenuItem(
                    value: RoutineFrequency.scheduled,
                    child: Text(isZh ? '指定日期 (一次性)' : 'Scheduled (one-time)')),
                DropdownMenuItem(
                    value: RoutineFrequency.adhoc,
                    child: Text(isZh ? '随时 (手动加入)' : 'Ad-hoc (manual)')),
              ],
              onChanged: (v) => setState(() {
                _frequency = v!;
              }),
            ),

            // Day-of-week picker (for weekly)
            if (_frequency == RoutineFrequency.weekly) ...[
              const SizedBox(height: 8),
              Text(isZh ? '选择星期' : 'Select days',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1; // 1=Mon…7=Sun
                  final selected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text((isZh ? _dayLabelsZh : _dayLabelsEn)[day]),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    }),
                  );
                }),
              ),
            ],

            // Date picker (for scheduled)
            if (_frequency == RoutineFrequency.scheduled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _scheduledDate == null
                        ? (isZh ? '未选择日期' : 'No date selected')
                        : isZh
                            ? '${_scheduledDate!.year}年${_scheduledDate!.month}月${_scheduledDate!.day}日'
                            : '${_scheduledDate!.year}-${_scheduledDate!.month.toString().padLeft(2, '0')}-${_scheduledDate!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _scheduledDate == null ? Colors.grey : null,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(isZh ? '选择日期' : 'Pick date'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Category
            Text(isZh ? '分类 (可选)' : 'Category (optional)',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RoutineCategory.values.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() {
                    _category = selected ? null : cat;
                  }),
                  child: Chip(
                    avatar: Image.asset(kCategoryIconPath[cat]!, width: 24, height: 24),
                    label: Text(routineCategoryName(cat, isZh), style: const TextStyle(fontSize: 12)),
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isZh ? '取消' : 'Cancel'),
        ),
        MergeSemantics(child: Semantics(
          identifier: 'btn_routine_dialog_save',
          child: TextButton(
            onPressed: _save,
            child: Text(widget.existing != null
                ? (isZh ? '保存' : 'Save')
                : (isZh ? '添加' : 'Add')),
          ),
        )),
      ],
    );
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    try {
      final savedRelative = await FileService().saveFile(picked.path);
      final fullPath = await FileService().getFullPath(savedRelative);
      if (mounted) setState(() => _iconImagePath = fullPath);
    } catch (e) {
      if (mounted) {
        final isZhPick = context.read<LocaleProvider>().locale.languageCode == 'zh';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isZhPick ? '图片保存失败: $e' : 'Failed to save image: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _save() async {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请输入习惯名称' : 'Please enter a name')),
      );
      return;
    }
    if (_frequency == RoutineFrequency.scheduled && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '请选择指定日期' : 'Please select a date')),
      );
      return;
    }
    final reminder = _reminderController.text.trim();
    if (reminder.isNotEmpty && !RegExp(r'^\d{2}:\d{2}$').hasMatch(reminder)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isZh ? '提醒时间格式应为 HH:MM (如 08:00)' : 'Reminder must be HH:MM (e.g. 08:00)')),
      );
      return;
    }
    final why = _whyController.text.trim().isEmpty
        ? null
        : _whyController.text.trim();
    final days = _frequency == RoutineFrequency.weekly && _selectedDays.isNotEmpty
        ? List<int>.from(_selectedDays)
        : null;
    final schedDate =
        _frequency == RoutineFrequency.scheduled ? _scheduledDate : null;

    final provider = context.read<RoutineProvider>();

    if (widget.existing != null) {
      // Preserve the other locale's name/description — dialog shows current locale only
      final updated = widget.existing!.copyWith(
        name: isZh ? name : widget.existing!.name,
        nameEn: isZh ? widget.existing!.nameEn : name,
        description: isZh ? (why ?? widget.existing!.description) : widget.existing!.description,
        descriptionEn: isZh ? widget.existing!.descriptionEn : (why ?? widget.existing!.descriptionEn),
        reminderTime: reminder,
        updatedAt: DateTime.now(),
        category: _category ?? RoutineCategory.other,
        clearCategory: false,
        frequency: _frequency,
        scheduledDaysOfWeek: days,
        scheduledDate: schedDate,
        clearScheduledDate: schedDate == null,
        iconImagePath: _iconImagePath,
        clearIconImagePath: _iconImagePath == null,
        isActive: _isActive,
        voiceEnabled: _voiceEnabled,
      );
      provider.updateRoutine(updated);
      // Reschedule notification
      if (reminder != null && reminder.isNotEmpty) {
        NotificationService.scheduleRoutine(updated, isZh);
      } else {
        NotificationService.cancelRoutine(updated.id, isZh);
      }
    } else {
      final newRoutine = await provider.addRoutine(
        name: name,
        nameEn: name,
        frequency: _frequency,
        reminderTime: reminder,
        category: _category ?? RoutineCategory.other,
        scheduledDaysOfWeek: days,
        scheduledDate: schedDate,
        iconImagePath: _iconImagePath,
        voiceEnabled: _voiceEnabled,
      );
      // Schedule notification
      if (newRoutine != null && reminder != null && reminder.isNotEmpty) {
        NotificationService.scheduleRoutine(newRoutine, isZh);
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.existing != null
              ? (isZh ? '习惯已更新' : 'Routine updated')
              : (isZh ? '习惯已添加' : 'Routine added'))),
    );
  }
}

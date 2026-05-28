import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/file_service.dart';
import '../../core/services/entitlement_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/routine_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/entry_provider.dart';
import '../../models/routine.dart';
import '../purchase/paywall_screen.dart';

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

class RoutineScreenState extends State<RoutineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Adhoc routines manually added to today's list (in-memory, not persisted)
  final Set<String> _manuallyAddedToday = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {}); // force rebuild on tab switch for fresh data
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static String _buildLabel(bool isZh) => isZh ? '建造' : 'Build';
  static String _doLabel(bool isZh) => isZh ? '执行' : 'Do';
  static String _reflectLabel(bool isZh) => isZh ? '反思' : 'Reflect';

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '日常 · 建造/执行/反思' : 'Routines · Build/Do/Reflect'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Semantics(identifier: 'routine_tab_build', child: Text(_buildLabel(isZh)))),
            Tab(child: Semantics(identifier: 'routine_tab_do', child: Text(_doLabel(isZh)))),
            Tab(child: Semantics(identifier: 'routine_tab_reflect', child: Text(_reflectLabel(isZh)))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BuildTab(onEdit: _showEditRoutineDialog),
          _DoTab(
            manuallyAdded: _manuallyAddedToday,
            onManualAdd: (id) => setState(() => _manuallyAddedToday.add(id)),
          ),
          const _ReflectTab(),
        ],
      ),
    );
  }

  void showAddRoutineDialog(BuildContext context) {
    final entitlement = context.read<EntitlementService>();
    if (!entitlement.canAddHabit) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    _RoutineDialog.show(context, existing: null);
  }

  void _showEditRoutineDialog(BuildContext context, Routine routine) {
    final entitlement = context.read<EntitlementService>();
    if (!entitlement.canEditNote) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    _RoutineDialog.show(context, existing: routine);
  }
}

// ─────────────────────────────────────────────
// Tab 1 — 建造 / Build
// ─────────────────────────────────────────────
class _BuildTab extends StatelessWidget {
  final void Function(BuildContext, Routine) onEdit;
  const _BuildTab({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final provider = context.watch<RoutineProvider>();
    final routines = provider.routines;
    final active = routines.where((r) => r.isActive).toList();
    final paused = routines.where((r) => !r.isActive).toList();

    if (routines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                isZh ? '开始建立你的日常习惯' : 'Start building your routine',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                isZh
                    ? '小的习惯，坚持做下去，\n会带来持久的改变。'
                    : 'Small habits, done consistently,\ncreate lasting change.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
          ],
        ),
      ),
    );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isZh ? '活跃' : 'Active',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${active.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...active.map((r) => _BuildRoutineTile(
                routine: r,
                onEdit: () => onEdit(context, r),
                onToggle: () => _toggleActive(context, r),
              )),
          const SizedBox(height: 16),
        ],
        if (paused.isNotEmpty) ...[
          Row(
            children: [
              Text(
                isZh ? '已暂停' : 'Paused',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${paused.length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...paused.map((r) => _BuildRoutineTile(
                routine: r,
                onEdit: () => onEdit(context, r),
                onToggle: () => _toggleActive(context, r),
              )),
        ],
      ],
    );
  }

  void _toggleActive(BuildContext context, Routine routine) {
    final entitlement = context.read<EntitlementService>();
    if (!entitlement.canEditNote) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    context.read<RoutineProvider>().toggleActive(routine.id);
  }
}

class _BuildRoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _BuildRoutineTile({
    required this.routine,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final active = routine.isActive;
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _buildRoutineIcon(routine, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.displayName(isZh),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: active ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routine.frequencyLabelFor(isZh),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (routine.description != null &&
                        routine.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          isZh
                              ? routine.description!
                              : (routine.descriptionEn ?? routine.description!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (!active && routine.streak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          isZh
                              ? '暂停 · 最佳记录 ${routine.streak} 天'
                              : 'Paused · best ${routine.streak} days',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: (_) => onToggle(),
                activeThumbColor: Theme.of(context).colorScheme.primary,
              ),
              GestureDetector(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.more_vert,
                      size: 18, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2 — 执行 / Do
// ─────────────────────────────────────────────
class _DoTab extends StatefulWidget {
  final Set<String> manuallyAdded;
  final void Function(String id) onManualAdd;

  const _DoTab({required this.manuallyAdded, required this.onManualAdd});

  @override
  State<_DoTab> createState() => _DoTabState();
}

class _DoTabState extends State<_DoTab> {
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
      padding: const EdgeInsets.all(16),
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
        final entitlement = context.read<EntitlementService>();
        if (!entitlement.canAddHabit) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
          return;
        }
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

// ─────────────────────────────────────────────
// Tab 3 — 反思 / Reflect
// ─────────────────────────────────────────────
class _ReflectTab extends StatelessWidget {
  const _ReflectTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Start from the earliest routine creation, capped at 60 days max
    final allRoutines = provider.routines;
    final earliestCreated = allRoutines.isNotEmpty
        ? allRoutines.map((r) => r.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : todayNorm;
    final earliestNorm = DateTime(earliestCreated.year, earliestCreated.month, earliestCreated.day);
    final maxLookback = todayNorm.difference(earliestNorm).inDays.clamp(1, 60);

    final days = List.generate(maxLookback, (i) {
      return todayNorm.subtract(Duration(days: i + 1));
    });

    final daysWithData = days.where((day) {
      return provider.getRoutinesForDate(day).isNotEmpty;
    }).toList();

    if (daysWithData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              isZh ? '还没有历史记录' : 'No history yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              isZh ? '完成习惯后会出现在这里' : 'Completed habits will appear here',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Active habits for summary cards
    final activeHabits =
        provider.routines.where((r) => r.isActive).toList();

    // Compute periodic summary
    final allCompletions = provider.routines
        .expand((r) => r.completionLog)
        .length;
    int bestStreak = 0;
    Routine? bestRoutine;
    Routine? worstRoutine;
    double worstRate = 1.0;
    for (final r in activeHabits) {
      if (r.streak > bestStreak) {
        bestStreak = r.streak;
        bestRoutine = r;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Periodic summary ──
        if (activeHabits.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(isZh ? 'yyyy年M月' : 'MMMM yyyy').format(today),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(children: [
                        Text('$allCompletions', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isZh ? '总完成' : 'Total', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(children: [
                        Text(bestStreak > 0 ? '$bestStreak ${isZh ? "天" : "d"}' : '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isZh ? '最佳连续' : 'Best streak', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(children: [
                        Text('${activeHabits.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(isZh ? '活跃习惯' : 'Active', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ]),
                    ),
                  ],
                ),
                if (bestRoutine != null && bestStreak >= 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    isZh
                        ? '${bestRoutine.displayName(isZh)} 连续 $bestStreak 天 🔥'
                        : '${bestRoutine.displayName(isZh)} — ${bestStreak}d streak 🔥',
                    style: TextStyle(color: Colors.teal[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Per-habit summary cards ──
        if (activeHabits.isNotEmpty) ...[
          Text(
            isZh ? '习惯总览' : 'Habit Overview',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            ),
            const SizedBox(height: 4),
          for (final habit in activeHabits)
            _HabitSummaryCard(habit: habit),
          const SizedBox(height: 24),
        ],

        // ── Calendar history ──
        for (final day in daysWithData)
          _ReflectDayRecord(
            day: day,
            routines: provider.getRoutinesForDate(day),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _HabitSummaryCard extends StatelessWidget {
  final Routine habit;
  const _HabitSummaryCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final theme = Theme.of(context);
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);

    // Monthly completion rate — count unique days, not total completions
    final todayDate = DateTime(now.year, now.month, now.day);
    final monthCompletionsDays = <String>{};
    for (final c in habit.completionLog) {
      final logDate = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day);
      // Skip future dates
      if (logDate.isAfter(todayDate)) continue;
      if (c.completedAt.isAfter(thisMonth.subtract(const Duration(seconds: 1)))) {
        monthCompletionsDays.add(
          '${c.completedAt.year}-${c.completedAt.month}-${c.completedAt.day}');
      }
    }
    final monthCompletions = monthCompletionsDays.length;
    final daysPassed = now.day;
    final monthRate = daysPassed > 0 ? (monthCompletions / daysPassed).clamp(0.0, 1.0) : 0.0;

    // Day-of-week patterns
    final dayNames = isZh
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dowCompletions = <int, int>{};
    for (var i = 1; i <= 7; i++) {
      dowCompletions[i] = 0;
    }
    for (final c in habit.completionLog) {
      final dow = c.completedAt.weekday; // 1=Mon
      dowCompletions[dow] = (dowCompletions[dow] ?? 0) + 1;
    }

    int? strongestDow;
    int? weakestDow;
    int maxVal = -1;
    int minVal = 999999;
    for (final e in dowCompletions.entries) {
      if (e.value > maxVal) {
        maxVal = e.value;
        strongestDow = e.key;
      }
      if (e.value < minVal) {
        minVal = e.value;
        weakestDow = e.key;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRoutineIcon(habit, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.displayName(isZh),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                _StatBadge(
                  label: isZh ? '连续' : 'Streak',
                  value: '${habit.streak} ${isZh ? "天" : "d"}',
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: isZh ? '本月' : 'Month',
                  value: '${(monthRate * 100).round()}%',
                ),
                const SizedBox(width: 10),
                _StatBadge(
                  label: isZh ? '完成' : 'Done',
                  value: '$monthCompletions / $daysPassed',
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Completion bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: monthRate,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  monthRate >= 0.8 ? Colors.teal : theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Strongest / weakest day
            if (strongestDow != null)
              Row(
                children: [
                  Text(
                    isZh ? '最强: ' : 'Strongest: ',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  _buildDayChip(dayNames[strongestDow - 1],
                      isStrong: true),
                  if (weakestDow != null && weakestDow != strongestDow) ...[
                    const SizedBox(width: 8),
                    Text(
                      isZh ? '最弱: ' : 'Weakest: ',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    _buildDayChip(dayNames[weakestDow - 1],
                        isStrong: false),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String day, {required bool isStrong}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isStrong ? Colors.teal.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        day,
        style: TextStyle(
          color: isStrong ? Colors.teal[700] : Colors.orange[700],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ReflectDayRecord extends StatelessWidget {
  final DateTime day;
  final List<Routine> routines;

  const _ReflectDayRecord({
    required this.day,
    required this.routines,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final format = DateFormat(isZh ? 'M月d日 (EEE)' : 'MMM d (EEE)', isZh ? 'zh' : 'en');
    final label = format.format(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: Colors.grey[200])),
            ],
          ),
        ),
        ...routines.map((r) {
          final done = r.isCompletedOn(day);
          final existed = !day.isBefore(r.createdAt);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: _buildReflectSymbol(done, existed),
                ),
                const SizedBox(width: 10),
                _buildRoutineIcon(r, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.displayName(isZh),
                    style: TextStyle(
                      color: done ? null : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _buildReflectSymbol(bool done, bool existed) {
    if (done) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
      );
    }
    if (existed) {
      return Icon(Icons.close, size: 14, color: Colors.deepOrange[300]);
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────
// Add / Edit dialog
// ─────────────────────────────────────────────
class _RoutineDialog {
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

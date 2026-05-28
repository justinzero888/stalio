import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/routine_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/jar_provider.dart';
import '../../models/routine.dart';
import '../../models/entry.dart';
import '../../core/services/entitlement_service.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/emoji_jar.dart';
import '../../core/services/soft_prompt_service.dart';
import '../../l10n/app_localizations.dart';
import '../add_entry_screen.dart';
import '../moment/entry_detail_screen.dart';

/// My Day — daily dashboard with calendar navigation + today's overview
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  bool _showOnboarding = false;
  bool _isCalendarExpanded = false;
  bool _carryForwardChecked = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _loadCalendarPrefs();
  }

  Future<void> _loadCalendarPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isCalendarExpanded = prefs.getBool('calendar_expanded') ?? false);
    }
  }

  Future<void> _toggleCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    final expanded = !_isCalendarExpanded;
    await prefs.setBool('calendar_expanded', expanded);
    setState(() => _isCalendarExpanded = expanded);
    if (expanded) {
      _focusedMonth = _selectedDate;
    }
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!done && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';

    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle(context)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: isZh ? '今天' : 'Today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Onboarding banner (first-launch only)
          if (_showOnboarding) _OnboardingBanner(onDismiss: _dismissOnboarding),
          // Calendar
          CalendarWidget(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            entryCounts: _getEntryCounts(),
            dayEmotions: _getDayEmotions(),
            dayHabitStatus: _getDayHabitStatus(),
            onDateSelected: _onDateSelected,
            onMonthChanged: _onMonthChanged,
            isExpanded: _isCalendarExpanded,
            onToggleExpand: _toggleCalendar,
          ),
          const Divider(height: 1),
          // Today's Overview
          Expanded(
            child: _buildTodayOverview(context),
          ),
        ],
      ),
    );
  }

  /// Get entry counts per date for calendar indicators
  Map<DateTime, int> _getEntryCounts() {
    final entries = context.read<EntryProvider>().entries;
    final Map<DateTime, int> counts = {};
    for (final entry in entries) {
      final date = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  /// Get dominant emotion per date for calendar display
  Map<DateTime, String?> _getDayEmotions() {
    final entryProvider = context.read<EntryProvider>();
    final datesWithEntries = entryProvider.getDatesWithEntries();
    final Map<DateTime, String?> emotions = {};
    for (final date in datesWithEntries) {
      final emotion = entryProvider.getDayEmotion(date);
      if (emotion != null) {
        emotions[date] = emotion;
      }
    }
    return emotions;
  }

  /// Compute habit completion status for each date in the focused month.
  Map<DateTime, ({int completed, int total})> _getDayHabitStatus() {
    final routineProvider = context.read<RoutineProvider>();
    final result = <DateTime, ({int completed, int total})>{};
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (day.isAfter(today)) break;
      final dayKey = DateTime(day.year, day.month, day.day);
      final scheduled = routineProvider.getRoutinesForDate(day);
      if (scheduled.isEmpty) continue;
      final completed = scheduled.where((r) => r.isCompletedOn(day)).length;
      result[dayKey] = (completed: completed, total: scheduled.length);
    }
    return result;
  }

  String _buildTitle(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final prefix = l?.myDay ?? (isZh ? '我的一天' : 'My Day');
    if (isToday) return prefix;
    if (isZh) {
      return '$prefix - ${_selectedDate.month}月${_selectedDate.day}日';
    }
    final df = DateFormat('MMM d');
    return '$prefix - ${df.format(_selectedDate)}';
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _focusedMonth = DateTime.now();
      _isCalendarExpanded = false;
    });
  }

  void _onDateSelected(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (date.isAfter(today) && !_isSameDay(date, today)) return;
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
    });
  }

  void _onMonthChanged(DateTime month) {
    setState(() {
      _focusedMonth = month;
    });
  }

  Widget _buildTodayOverview(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final isZh = locale.languageCode == 'zh';
    final entries = context.watch<EntryProvider>().entries;
    final routineProvider = context.watch<RoutineProvider>();
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isPastDay = !isToday && _selectedDate.isBefore(DateTime.now());
    final entryProvider = context.read<EntryProvider>();

    _scheduleCarryForwardCheck(entryProvider);

    // Get selected day's entries
    final dayEntries = entries.where((e) =>
      _isSameDay(e.createdAt, _selectedDate)
    ).toList();

    final dayListEntries = dayEntries.where((e) => e.format == EntryFormat.list).toList();
    final dayNoteEntries = dayEntries.where((e) => e.format != EntryFormat.list).toList();

    final dayRoutines = routineProvider.getRoutinesForDate(_selectedDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Header
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat(isZh ? 'yyyy年M月d日 EEEE' : 'EEEE, MMMM d, yyyy')
                    .format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Builder(builder: (context) {
              final emotion = context.watch<EntryProvider>().getDayEmotion(_selectedDate);
              if (emotion == null) return const SizedBox.shrink();
              return Text(emotion, style: const TextStyle(fontSize: 22));
            }),
          ],
        ),
        const SizedBox(height: 16),

        // List Entries Section — pinned above habits
        if (dayListEntries.isNotEmpty) ...[
          Text(
            isZh ? '📋 今日清单' : '📋 Lists',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...dayListEntries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EntryCard(
              entry: entry,
              onTap: () => _onEntryTapped(entry),
            ),
          )),
        ],

        // Routines Section
        if (dayRoutines.isNotEmpty) ...[
          Text(
            isZh ? '✅ 习惯打卡' : '✅ Habit Check-in',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          // Pending: for past days consolidate into a red icon row;
          // for today show individually with checkbox
          Builder(builder: (context) {
            final pending = dayRoutines
                .where((r) => !r.isCompletedOn(_selectedDate))
                .toList();
            if (pending.isEmpty) return const SizedBox.shrink();
            if (isPastDay) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: pending
                              .map((r) => Text(r.effectiveIcon,
                                  style: const TextStyle(fontSize: 22)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: pending
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildRoutineChecklistItem(context, r),
                      ))
                  .toList(),
            );
          }),
          // Completed: one consolidated icon row
          Builder(builder: (context) {
            final done = dayRoutines
                .where((r) => r.isCompletedOn(_selectedDate))
                .toList();
            if (done.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 6,
                        children: done
                            .map((r) => Text(r.effectiveIcon,
                                style: const TextStyle(fontSize: 22)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Notes Section
        if (dayNoteEntries.isNotEmpty) ...[
          Text(
            isZh ? '📝 笔记' : '📝 Notes',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...dayNoteEntries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EntryCard(
              entry: entry,
              onTap: () => _onEntryTapped(entry),
            ),
          )),
        ],

        // Emoji Jar Section — show when there are entries for the day
        if (dayListEntries.isNotEmpty || dayNoteEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          _EmojiJarSection(
            date: _selectedDate,
            canUseAI: context.watch<EntitlementService>().canUseAI,
          ),
        ],

        // Empty State
        if (dayListEntries.isEmpty && dayNoteEntries.isEmpty && dayRoutines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isZh
                        ? (isToday ? '今天还没有记录' : '当天没有记录')
                        : (isToday ? 'No entries today' : 'No entries on this day'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isZh ? '点击 + 添加记录' : 'Tap + to add an entry',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoutineChecklistItem(BuildContext context, Routine routine, {bool readOnly = false}) {
    final isCompleted = routine.isCompletedOn(_selectedDate);
    final isMissed = readOnly && !isCompleted;
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';

    return Card(
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          routine.displayName(isZh),
          style: TextStyle(
            color: isMissed ? Colors.red[300] : null,
          ),
        ),
        onTap: readOnly
            ? null
            : () async {
                context.read<RoutineProvider>().toggleComplete(routine.id, date: _selectedDate);
                await SoftPromptService.maybeShow(context);
              },
      ),
    );
  }

  void _scheduleCarryForwardCheck(EntryProvider entryProvider) {
    if (_carryForwardChecked) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _carryForwardChecked) return;
      _carryForwardChecked = true;
      final items = entryProvider.getCarryForwardPreview();
      if (items != null && items.isNotEmpty) {
        _showCarryForwardDialog(entryProvider, items);
      }
    });
  }

  Future<void> _showCarryForwardDialog(EntryProvider entryProvider, List<ListItem> items) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = 'carry_forward_dialog_${today.year}_${today.month}_${today.day}';
    if (prefs.getBool(todayKey) == true) return;

    final l = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.carryForwardDialogTitle),
        content: Text(l.carryForwardDialogMessage(items.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.carryForwardNo),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.carryForwardYes),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await prefs.setBool(todayKey, true);

    if (result == true) {
      await entryProvider.carryForwardItems(items);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onEntryTapped(Entry entry) {
    final today = DateTime.now();
    final entryDay = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
    final todayDay = DateTime(today.year, today.month, today.day);

    if (entryDay.isBefore(todayDay)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(entry: entry),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEntryScreen(existingEntry: entry),
        ),
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// First-launch onboarding banner shown at the top of the Calendar screen
class _OnboardingBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _OnboardingBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              isZh
                  ? '欢迎使用 Blinking 记忆闪烁。生命是一呼一吸、一食一化、一睁一闭。留意、记取，且惜取身边点滴清欢。'
                  : 'Welcome to Blinking Notes. Life is breath in and out, eat and digest, blink — eyes open and shut. Notice, note, and cherish the little things around you.',
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.close, size: 18, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible mood jar section with AI reflection button
class _EmojiJarSection extends StatefulWidget {
  final DateTime date;
  final bool canUseAI;
  const _EmojiJarSection({required this.date, required this.canUseAI});

  @override
  State<_EmojiJarSection> createState() => _EmojiJarSectionState();
}

class _EmojiJarSectionState extends State<_EmojiJarSection> {
  bool _expanded = true;
  List<Map<String, String>> _reflections = [];
  bool _loaded = false;

  String _dateKey(DateTime d) =>
      '${d.year}_${d.month}_${d.day}';

  Future<void> _loadReflections() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mood_reflections_${_dateKey(widget.date)}';
    final json = prefs.getString(key);
    if (mounted) {
      setState(() {
        if (json != null) {
          try {
            _reflections = (jsonDecode(json) as List)
                .map((e) => Map<String, String>.from(e as Map))
                .toList();
          } catch (_) {
            _reflections = [];
          }
        } else {
          _reflections = [];
        }
        _loaded = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  @override
  void didUpdateWidget(covariant _EmojiJarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadReflections();
    }
  }

  String _formatDate(DateTime date, bool isZh) {
    final day = DateFormat('E·MMMd', isZh ? 'zh' : 'en').format(date);
    // Remove comma: "Mon·May 9" instead of "Mon,May 9"
    return day.replaceAll(',', '');
  }

  bool get _isToday =>
      widget.date.year == DateTime.now().year &&
      widget.date.month == DateTime.now().month &&
      widget.date.day == DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final emotions = context.watch<JarProvider>().getDayEmotions(widget.date);
    final hasEmoji = emotions.isNotEmpty;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Text('🫙', style: TextStyle(fontSize: 20)),
            title: Text(
              isZh
                  ? '情绪罐 — ${_formatDate(widget.date, isZh)}'
                  : 'My Mood Jar — ${_formatDate(widget.date, isZh)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: EmojiJarWidget(
                date: widget.date,
                canUseAI: widget.canUseAI,
                isToday: _isToday,
                existingReflections: _reflections,
                onReflectionSaved: _loadReflections,
              ),
            ),
        ],
      ),
    );
  }
}

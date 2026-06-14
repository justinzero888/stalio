import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../providers/routine_provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/routine.dart';
import '../../models/entry.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/entry_card.dart';
import '../moment/entry_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../add_entry_screen.dart';
import '../../l10n/app_localizations.dart';

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
  bool _isCalendarExpanded = false;
  bool _carryForwardChecked = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_buildTitle(context, l)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: l.today,
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: _buildTodayOverview(context, l),
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

  String _buildTitle(BuildContext context, AppLocalizations l) {
    final isZh = context.read<LocaleProvider>().locale.languageCode == 'zh';
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final prefix = l.appTitleTagline;
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

  Widget _buildTodayOverview(BuildContext context, AppLocalizations l) {
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
            l.listsSectionHeader,
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
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFE0B84F), size: 18),
              const SizedBox(width: 6),
              Text(
                l.habitCheckIn,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: l.editHabits,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(initialTab: 2),
                    ),
                  );
                },
              ),
            ],
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
                      Icon(Icons.check_circle, color: const Color(0xFFE0B84F), size: 18),
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
            l.notesSectionHeader,
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
                    isToday ? l.noEntriesEmptyToday : l.noEntriesEmptyPast,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.noEntriesEmptyAction,
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
    final l = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
          color: isCompleted ? const Color(0xFFE0B84F) : Colors.grey,
        ),
        title: Text(
          routine.displayName(l.localeName == 'zh'),
          style: TextStyle(
            color: isMissed ? Colors.red[300] : null,
          ),
        ),
        onTap: readOnly
            ? null
            : () {
                context.read<RoutineProvider>().toggleComplete(routine.id, date: _selectedDate);
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
    final l = AppLocalizations.of(context)!;
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
              l.welcomeBannerText,
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

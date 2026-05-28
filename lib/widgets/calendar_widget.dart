import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Map<DateTime, int> entryCounts;
  final Map<DateTime, String?> dayEmotions;
  final Map<DateTime, ({int completed, int total})> dayHabitStatus;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.focusedMonth,
    required this.entryCounts,
    this.dayEmotions = const {},
    this.dayHabitStatus = const {},
    required this.onDateSelected,
    required this.onMonthChanged,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  static DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _maxNavigableMonth(DateTime today) {
    final year = today.month + 2 > 12 ? today.year + 1 : today.year;
    final month = today.month + 2 > 12 ? today.month + 2 - 12 : today.month + 2;
    return DateTime(year, month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayStart();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final effectiveExpanded = isLandscape ? false : isExpanded;

    return Column(
      children: [
        _buildHeader(context, today, isLandscape),
        _buildWeekdayLabels(context),
        if (effectiveExpanded)
          _buildCalendarGrid(context, today)
        else
          _buildWeekStrip(context, today),
      ],
    );
  }

  bool _isZh(BuildContext context) =>
      context.watch<LocaleProvider>().locale.languageCode == 'zh';

  Widget _buildHeader(BuildContext context, DateTime today, bool isLandscape) {
    final maxMonth = _maxNavigableMonth(today);
    final atMaxMonth = focusedMonth.year == maxMonth.year &&
        focusedMonth.month >= maxMonth.month;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final previousMonth = DateTime(
                focusedMonth.year,
                focusedMonth.month - 1,
              );
              onMonthChanged(previousMonth);
            },
          ),
          Text(
            _isZh(context)
                ? DateFormat('yyyy年M月').format(focusedMonth)
                : DateFormat('MMMM yyyy').format(focusedMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLandscape && onToggleExpand != null)
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                  onPressed: onToggleExpand,
                ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: atMaxMonth
                    ? null
                    : () {
                        final nextMonth = DateTime(
                          focusedMonth.year,
                          focusedMonth.month + 1,
                        );
                        onMonthChanged(nextMonth);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    final weekdays = _isZh(context)
        ? ['日', '一', '二', '三', '四', '五', '六']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Week Strip (collapsed state) ────────────────────────────

  Widget _buildWeekStrip(BuildContext context, DateTime today) {
    final weekStart = _weekStartFor(selectedDate);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: days.map((day) {
          final isFuture = day.isAfter(today) && !_isSameDay(day, today);
          final isSelected = _isSameDay(day, selectedDate);
          final isToday = _isSameDay(day, today);
          final dayKey = DateTime(day.year, day.month, day.day);
          final emotion = dayEmotions[dayKey];
          final habitStatus = dayHabitStatus[dayKey];

          return Expanded(
            child: GestureDetector(
              onTap: isFuture ? null : () => onDateSelected(day),
              child: Opacity(
                opacity: isFuture ? 0.35 : 1.0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    border: isToday
                        ? Border.all(color: const Color(0xFF2A9D8F), width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isToday ? FontWeight.bold : null,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (emotion != null)
                        Text(emotion, style: const TextStyle(fontSize: 12))
                      else if (_hasEntries(day))
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (habitStatus != null && habitStatus.total > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SizedBox(
                            width: double.infinity,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: habitStatus.completed / habitStatus.total,
                                backgroundColor: isSelected ? Colors.white38 : Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  habitStatus.completed == habitStatus.total
                                      ? (isSelected ? Colors.white : Colors.green)
                                      : (isSelected ? Colors.white70 : Colors.orange),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  DateTime _weekStartFor(DateTime date) {
    final weekday = date.weekday % 7; // Sunday = 0, Monday = 1, ...
    return date.subtract(Duration(days: weekday));
  }

  // ── Full Calendar Grid (expanded state) ─────────────────────

  Widget _buildCalendarGrid(BuildContext context, DateTime today) {
    final days = _generateDaysInMonth();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) {
          return const SizedBox.shrink();
        }
        return _buildDayCell(context, day, today);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime day, DateTime today) {
    final isToday = _isSameDay(day, today);
    final isFuture = day.isAfter(today) && !isToday;
    final isSelected = _isSameDay(day, selectedDate);
    final isCurrentMonth = day.month == focusedMonth.month;
    final dayKey = DateTime(day.year, day.month, day.day);
    final emotion = dayEmotions[dayKey];
    final habitStatus = dayHabitStatus[dayKey];
    final hasEntries = _hasEntries(day);

    final cell = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected && !isFuture
            ? Theme.of(context).colorScheme.primary
            : null,
        border: isToday
            ? Border.all(color: const Color(0xFF2A9D8F), width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Opacity(
        opacity: isFuture ? 0.35 : 1.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected && !isFuture
                    ? Colors.white
                    : isCurrentMonth
                        ? Colors.black87
                        : Colors.grey,
                fontWeight: isToday ? FontWeight.bold : null,
                fontSize: 12,
              ),
            ),
            if (emotion != null)
              Text(emotion, style: const TextStyle(fontSize: 10))
            else if (hasEntries)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected && !isFuture
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            if (habitStatus != null && habitStatus.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 24,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: habitStatus.completed / habitStatus.total,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        habitStatus.completed == habitStatus.total
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (isFuture) return cell;

    return GestureDetector(
      onTap: () => onDateSelected(day),
      child: cell,
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  List<DateTime?> _generateDaysInMonth() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final List<DateTime?> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(null);
    }
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(focusedMonth.year, focusedMonth.month, i));
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasEntries(DateTime day) {
    return entryCounts.keys.any((date) => _isSameDay(date, day));
  }
}

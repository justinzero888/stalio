import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/tag_provider.dart';
import 'tag_analytics_tab.dart';
import '../moment/moment_screen.dart';
import '../../providers/jar_provider.dart';
import '../../widgets/emoji_jar.dart';
import '../../providers/routine_provider.dart';
import '../../models/routine.dart';
import '../../models/tag.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '统计' : 'Tallies'),
        centerTitle: true,
      ),
      body: const _InsightsContent(),
    );
  }
}

class _InsightsContent extends StatefulWidget {
  const _InsightsContent();
  @override
  State<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<_InsightsContent> {
  @override
  Widget build(BuildContext ctx) {
    final summary = ctx.watch<SummaryProvider>();
    final jarProvider = ctx.watch<JarProvider>();
    final isZh = ctx.watch<LocaleProvider>().locale.languageCode == 'zh';
    final years = jarProvider.yearsWithData;

    if (summary.totalEntries == 0) {
      if (summary.isLoading) return const Center(child: CircularProgressIndicator());
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.insights, size: 48, color: ctx.theme().colorScheme.outline),
        const SizedBox(height: 16),
        Text(isZh ? 'Start journaling to see insights' : 'Start journaling to see insights', style: ctx.theme().textTheme.bodyLarge?.copyWith(color: ctx.theme().colorScheme.outline)),
      ])));
    }

    return DefaultTabController(length: 2, child: Column(children: [
      
      TabBar(tabs: [Tab(text: isZh?'习惯':'Habits'),Tab(text: isZh?'笔记':'Notes')]),
      Expanded(child: TabBarView(children: [
        _buildHabitsContent(summary, isZh),
        const MomentScreen(),
        
      ])),
    ]));
  }
}

  Widget _buildHabitsContent(SummaryProvider summary, bool isZh) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _HeroStatsRow(summary: summary, isZh: isZh),
      const SizedBox(height: 16),
      _HabitsTab(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      TagAnalyticsTab(summary: summary, isZh: isZh),
    ]);
  }


class _HabitsTab extends StatelessWidget {
  final SummaryProvider summary; final bool isZh;
  const _HabitsTab({required this.summary, required this.isZh});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RoutineProvider>();
    final active = p.routines.where((r) => r.isActive).toList();
    int best = 0;
    for (final r in active) { if (r.streak > best) best = r.streak; }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      _SectionCard(title: isZh?'Habit Stats':'Habit Stats', child: SizedBox(height: 110, child: Row(children: [
        Expanded(child: _MiniStatCard(icon: Icons.checklist, value: '${p.routines.length}', label: isZh?'Total':'Total')),
        const SizedBox(width: 8),
        Expanded(child: _MiniStatCard(icon: Icons.local_fire_department, value: '$best${isZh?"d":"d"}', label: isZh?'Best Streak':'Best Streak')),
        const SizedBox(width: 8),
        Expanded(child: _MiniStatCard(icon: Icons.play_circle, value: '${active.length}', label: isZh?'Active':'Active')),
      ]))),
      if (active.isNotEmpty) ...[const SizedBox(height: 24), _StreakMatrixSection(routines: active)],
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Habit Completion':'Habit Completion', trailing: _ScopePicker(scope: summary.scope, onChanged: summary.setScope), child: _RoutineCompletionChart(provider: summary)),
    ]);
  }
}

class _NotesTab extends StatelessWidget {
  final SummaryProvider summary; final bool isZh;
  const _NotesTab({required this.summary, required this.isZh});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      _SectionCard(title: isZh?'Writing Stats':'Writing Stats', child: _WritingStatsSection(summary: summary, isZh: isZh)),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Writing Activity':'Writing Activity', trailing: summary.totalEntries>0?Text('${summary.totalEntries} ${isZh?"entries":"entries"}',style:TextStyle(color:Colors.grey[400],fontSize:12)):null, child: _CalendarHeatmap(entriesPerDay: summary.entriesPerDay)),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Notes Trend':'Notes Trend', trailing: _ScopePicker(scope: summary.scope, onChanged: summary.setScope), child: _NoteCountChart(provider: summary)),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Checklist Insights':'Checklist Insights', child: _ChecklistInsightsSection(summary: summary, isZh: isZh)),
    ]);
  }
}

class _MoodsTab extends StatelessWidget {
  final SummaryProvider summary; final List<int> years; final bool isZh;
  const _MoodsTab({required this.summary, required this.years, required this.isZh});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      _EmojiJarSection(years: years, isZh: isZh),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Mood Distribution':'Mood Distribution', child: _MoodDistributionChart(moodDistribution: summary.moodDistribution)),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Mood Trend':'Mood Trend', trailing: _ScopePicker(scope: summary.scope, onChanged: summary.setScope), child: _EmotionTrendChart(provider: summary)),
      const SizedBox(height: 24),
      _SectionCard(title: isZh?'Tag Impact on Mood':'Tag Impact on Mood', child: _TagMoodSection(summary: summary, isZh: isZh)),
    ]);
  }
}

class _StreakMatrixSection extends StatelessWidget {
  final List<Routine> routines;
  const _StreakMatrixSection({required this.routines});
  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final now = DateTime.now(), today = DateTime(now.year, now.month, now.day);
    DateTime earliest = today;
    for (final r in routines) {
      for (final c in r.completionLog) { final d = DateTime(c.completedAt.year, c.completedAt.month, c.completedAt.day); if (d.isBefore(earliest)) earliest = d; }
      final rd = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day); if (rd.isBefore(earliest)) earliest = rd;
    }
    while (earliest.weekday != DateTime.sunday) earliest = earliest.subtract(const Duration(days: 1));
    final weeks = <List<DateTime>>[]; var c = earliest;
    while (c.isBefore(today) || c == today) { weeks.add(List.generate(7, (d)=>DateTime(c.year, c.month, c.day).add(Duration(days:d)))); c = c.add(const Duration(days:7)); }
    const s = 12.0;
    return _SectionCard(title: isZh?'Streak Matrix':'Streak Matrix', child: Padding(padding: const EdgeInsets.all(12), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...routines.map((r) => Padding(padding: const EdgeInsets.only(bottom:6), child: Row(children: [
        SizedBox(width:100, child: Row(children: [Text(r.effectiveIcon, style: const TextStyle(fontSize:12)), const SizedBox(width:4), Expanded(child: Text(r.displayName(isZh), style: const TextStyle(fontSize:11, fontWeight:FontWeight.w500), overflow:TextOverflow.ellipsis))])),
        ...weeks.map((w)=>Row(children: w.map((d){final done=r.isCompletedOn(d);return Container(width:s,height:s,margin:const EdgeInsets.all(1),decoration:BoxDecoration(color:d.isAfter(today)?Colors.transparent:(done?Theme.of(context).colorScheme.primary:Colors.grey[200]),borderRadius:BorderRadius.circular(2)));}).toList())),
      ]))),
      Row(children: [
        Container(width:10,height:10,margin:const EdgeInsets.all(1),decoration:BoxDecoration(color:Colors.grey[200]!,borderRadius:BorderRadius.circular(1))),
        const SizedBox(width:4),Text(isZh?'Missed':'Missed',style:const TextStyle(fontSize:10,color:Colors.grey)),
        const SizedBox(width:12),
        Container(width:10,height:10,margin:const EdgeInsets.all(1),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(1))),
        const SizedBox(width:4),Text(isZh?'Done':'Done',style:const TextStyle(fontSize:10,color:Colors.grey)),
      ]),
    ]))));
  }
}

extension _ on BuildContext {
  ThemeData theme() => Theme.of(this);
}

class _HeroStatsRow extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;

  const _HeroStatsRow({required this.summary, required this.isZh});

  @override
  Widget build(BuildContext context) {
    final jarProvider = context.watch<JarProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEmotions = jarProvider.getDayEmotions(today);
    String todayMood;
    if (todayEmotions.isEmpty) {
      todayMood = '---';
    } else {
      final dominant = _dominantEmotion(todayEmotions);
      todayMood = dominant;
    }

    final habitRate = (summary.recentHabitCompletionRate * 100).round();

    final cards = [
      _HeroCardData(
        label: isZh ? '总记录' : 'Entries',
        value: '${summary.totalEntries}',
        icon: Icons.edit_note,
        color: const Color(0xFF10317D),
      ),
      _HeroCardData(
        label: isZh ? '连续天数' : 'Day Streak',
        value: '${summary.currentStreak}',
        icon: Icons.local_fire_department,
        color: const Color(0xFFE76F51),
        onTap: () {
          _showStreakTooltip(context, summary, isZh);
        },
      ),
      _HeroCardData(
        label: isZh ? '习惯完成' : 'Habit Rate',
        value: '$habitRate%',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF10317D),
      ),
      _HeroCardData(
        label: isZh ? '本周心情' : 'Week Mood',
        value: todayMood,
        icon: Icons.sentiment_satisfied_alt,
        color: const Color(0xFFE9C46A),
      ),
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  _HeroCard(data: cards[i], width: constraints.maxWidth),
            ),
          ),
        ],
      ],
    );
  }

  String _dominantEmotion(List<String> emotions) {
    final counts = <String, int>{};
    for (final e in emotions) {
      counts[e] = (counts[e] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void _showStreakTooltip(
      BuildContext context, SummaryProvider summary, bool isZh) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isZh ? '写作记录' : 'Writing Streak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _streakRow(
                isZh ? '当前连续' : 'Current streak',
                '${summary.currentStreak} ${isZh ? '天' : 'days'}'),
            const SizedBox(height: 8),
            _streakRow(
                isZh ? '最长连续' : 'Longest streak',
                '${summary.longestStreak} ${isZh ? '天' : 'days'}'),
            const SizedBox(height: 8),
            _streakRow(
                isZh ? '总记录天数' : 'Total active days',
                '${summary.entriesPerDay.length} ${isZh ? '天' : 'days'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isZh ? '关闭' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _streakRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HeroCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HeroCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _HeroCard extends StatelessWidget {
  final _HeroCardData data;
  final double width;

  const _HeroCard({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 22, color: data.color),
              const SizedBox(height: 6),
              Text(
                data.value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  final Map<DateTime, int> entriesPerDay;

  const _CalendarHeatmap({required this.entriesPerDay});

  static const double _cellSize = 16;
  static const double _gap = 3;
  static const List<String> _dayLabels = ['', 'Mon', '', 'Wed', '', 'Fri', ''];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;
    if (entriesPerDay.isNotEmpty) {
      final earliest =
          entriesPerDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
      startDate = DateTime(earliest.year, earliest.month, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 90));
    }
    while (startDate.weekday != DateTime.sunday) {
      startDate = startDate.subtract(const Duration(days: 1));
    }

    DateTime endDate = today;
    while (endDate.weekday != DateTime.saturday) {
      endDate = endDate.add(const Duration(days: 1));
    }

    final weeks = <List<DateTime>>[];
    var cursor = startDate;
    while (cursor.isBefore(endDate) || cursor == endDate) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: _dayLabels
                  .map((l) => SizedBox(
                        height: _cellSize + _gap,
                        child: l.isNotEmpty
                            ? Center(
                                child: Text(l,
                                    style: const TextStyle(fontSize: 9, color: Colors.grey)))
                            : null,
                      ))
                  .toList(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 7 * (_cellSize + _gap),
                      child: Row(
                        children: weeks.asMap().entries.map((w) {
                          final week = w.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: _gap),
                            child: Column(
                              children: week.map((day) {
                                final count = entriesPerDay[day] ?? 0;
                                final isFuture = day.isAfter(today);
                                return Container(
                                  width: _cellSize,
                                  height: _cellSize,
                                  margin: EdgeInsets.only(bottom: _gap),
                                  decoration: BoxDecoration(
                                    color: _heatColor(count, isFuture),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 14,
                      width: weeks.length * (_cellSize + _gap),
                      child: Stack(
                        children: months.entries.map((m) {
                          final isZh = _isZhFromContext(context);
                          final dateFormat = DateFormat(isZh ? 'M月' : 'MMM');
                          final label = dateFormat.format(DateTime(2020, m.key));
                          final left =
                              m.value * (_cellSize + _gap);
                          return Positioned(
                            left: left,
                            child: Text(
                              label,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Less ', style: TextStyle(fontSize: 9, color: Colors.grey)),
            _legendBox(const Color(0xFFE8E8E8)),
            _legendBox(const Color(0xFF9CD4CB)),
            _legendBox(const Color(0xFF10317D)),
            _legendBox(const Color(0xFF0A151F)),
            const Text(' More', style: TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  bool _isZhFromContext(BuildContext context) {
    try {
      return context.read<LocaleProvider>().locale.languageCode == 'zh';
    } catch (_) {
      return false;
    }
  }

  Color _heatColor(int count, bool isFuture) {
    if (isFuture) return Colors.grey[100]!;
    if (count == 0) return const Color(0xFFE8E8E8);
    if (count == 1) return const Color(0xFF9CD4CB);
    if (count <= 3) return const Color(0xFF10317D);
    if (count <= 5) return const Color(0xFF1A7A6E);
    return const Color(0xFF0A151F);
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _MoodDistributionChart extends StatelessWidget {
  final Map<String, int> moodDistribution;

  const _MoodDistributionChart({required this.moodDistribution});

  static const _moodGroups = {
    '😊': ['😊', '🥰', '🤩'],
    '😌': ['😌'],
    '😐': ['😐', '😴'],
    '😢': ['😔', '😢', '😰', '😤'],
    '😡': ['😡'],
  };

  static const _moodColors = {
    '😊': Color(0xFF10317D),
    '😌': Color(0xFFA8DADC),
    '😐': Color(0xFFE9C46A),
    '😢': Color(0xFF457B9D),
    '😡': Color(0xFFE76F51),
  };

  static const _moodLabels = {
    '😊': {'en': 'Great', 'zh': '很好'},
    '😌': {'en': 'Good', 'zh': '不错'},
    '😐': {'en': 'Okay', 'zh': '一般'},
    '😢': {'en': 'Low', 'zh': '低落'},
    '😡': {'en': 'Rough', 'zh': '不好'},
  };

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final grouped = _groupMoods();

    if (grouped.isEmpty) {
      return _emptyWidget(context);
    }

    final total = grouped.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: grouped.entries.map((e) {
                final pct = (e.value / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  color: _moodColors[e.key] ?? Colors.grey,
                  value: e.value.toDouble(),
                  title: '$pct%',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  radius: 50,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: grouped.entries.map((e) {
            final label =
                isZh ? _moodLabels[e.key]!['zh']! : _moodLabels[e.key]!['en']!;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _moodColors[e.key],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$label (${e.value})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Map<String, int> _groupMoods() {
    final grouped = <String, int>{};
    for (final entry in moodDistribution.entries) {
      String? groupKey;
      for (final g in _moodGroups.entries) {
        if (g.value.contains(entry.key)) {
          groupKey = g.key;
          break;
        }
      }
      if (groupKey != null) {
        grouped[groupKey] = (grouped[groupKey] ?? 0) + entry.value;
      }
    }
    grouped.removeWhere((_, v) => v == 0);
    return grouped;
  }

  Widget _emptyWidget(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          isZh ? '暂无情绪数据' : 'No mood data yet',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class _EmojiJarSection extends StatelessWidget {
  final List<int> years;
  final bool isZh;

  const _EmojiJarSection({required this.years, required this.isZh});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: isZh ? '🫙 情绪罐' : '🫙 Mood Jars',
      child: SizedBox(
        height: 200,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: years.map((year) {
            final jarProvider = context.watch<JarProvider>();
            final emotions = jarProvider.getYearEmotions(year);

            return SizedBox(
              width: 120,
              child: Column(
                children: [
                  EmojiJarWidget(
                    date: DateTime(year),
                    emotionsOverride: emotions,
                    size: 120,
                    canUseAI: false,
                    isToday: false,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$year',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                  Text(
                    isZh ? '${emotions.length} 个心情' : '${emotions.length} moods',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ),
  ));
  }}
class _TrendCharts extends StatelessWidget {
  const _TrendCharts();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SummaryProvider>();
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l.summaryNoteCount),
        const SizedBox(height: 8),
        _NoteCountChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryHabitCompletion),
        const SizedBox(height: 8),
        _RoutineCompletionChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryMoodTrend),
        const SizedBox(height: 8),
        _EmotionTrendChart(provider: provider),
        const SizedBox(height: 24),

        _SectionTitle(title: l.summaryTopTags),
        const SizedBox(height: 8),
        _TopTagsChart(provider: provider),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ScopePicker extends StatelessWidget {
  final SummaryScope scope;
  final void Function(SummaryScope) onChanged;

  const _ScopePicker({required this.scope, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScopeChip(
          label: isZh ? '日' : 'Day',
          selected: scope == SummaryScope.daily,
          onTap: () => onChanged(SummaryScope.daily),
        ),
        const SizedBox(width: 4),
        _ScopeChip(
          label: isZh ? '周' : 'Week',
          selected: scope == SummaryScope.weekly,
          onTap: () => onChanged(SummaryScope.weekly),
        ),
        const SizedBox(width: 4),
        _ScopeChip(
          label: isZh ? '月' : 'Month',
          selected: scope == SummaryScope.monthly,
          onTap: () => onChanged(SummaryScope.monthly),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _NoteCountChart extends StatelessWidget {
  final SummaryProvider provider;
  const _NoteCountChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final counts = provider.noteCounts;
    if (counts.isEmpty) {
      return const _EmptyChart();
    }
    final maxCount = counts.map((c) => c.count).reduce((a, b) => a > b ? a : b);
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final dateFormat = DateFormat(isZh ? 'M/d' : 'M/d');

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceilToDouble().clamp(1, double.infinity),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${counts[group.x.toInt()].count}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < counts.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateFormat.format(counts[index].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _niceInterval(maxCount),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: counts.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  color: const Color(0xFF10317D),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoutineCompletionChart extends StatelessWidget {
  final SummaryProvider provider;
  const _RoutineCompletionChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final rates = provider.routineCompletionRates(isZh: isZh);
    final allZero = rates.isEmpty || rates.values.every((v) => v == 0.0);
    if (allZero) {
      return const _EmptyChart();
    }
    final entries = rates.entries.toList();

    return SizedBox(
      height: entries.length * 40.0 + 20,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${(entries[group.x.toInt()].value * 100).toStringAsFixed(0)}%',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entries[index].key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 0.25,
                getTitlesWidget: (value, meta) => Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: const Color(0xFF10317D),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmotionTrendChart extends StatelessWidget {
  final SummaryProvider provider;
  const _EmotionTrendChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final trend = provider.emotionTrend;
    if (trend.isEmpty) {
      return const _EmptyChart();
    }

    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final dateFormat = DateFormat(isZh ? 'M/d' : 'M/d');
    final minVal = 1.0;
    final maxVal = 5.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minVal - 0.5,
          maxY: maxVal + 0.5,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final emojis = ['', '😡', '😢', '😐', '😌', '😊'];
                  final idx = spot.y.round().clamp(1, 5);
                  return LineTooltipItem(
                    emojis[idx],
                    const TextStyle(fontSize: 20),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval:
                    (trend.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < trend.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateFormat.format(trend[index].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 5: return const Text('😊', style: TextStyle(fontSize: 12));
                    case 4: return const Text('😌', style: TextStyle(fontSize: 12));
                    case 3: return const Text('😐', style: TextStyle(fontSize: 12));
                    case 2: return const Text('😢', style: TextStyle(fontSize: 12));
                    case 1: return const Text('😡', style: TextStyle(fontSize: 12));
                    default: return const SizedBox.shrink();
                  }
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: trend.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.score);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF10317D),
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF10317D).withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTagsChart extends StatelessWidget {
  final SummaryProvider provider;
  const _TopTagsChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final topTags = provider.topTags;
    if (topTags.isEmpty || tagProvider.tags.isEmpty) {
      return const _EmptyChart();
    }
    final maxCount =
        topTags.map((t) => t.count).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: topTags.length * 36.0 + 20,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxCount * 1.2).ceilToDouble().clamp(1, double.infinity),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${topTags[group.x.toInt()].count}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topTags.length) {
                    final tagId = topTags[index].tagId;
                    final tag = tagProvider.tags.firstWhere(
                      (t) => t.id == tagId,
                      orElse: () => tagProvider.tags.isNotEmpty ? tagProvider.tags.first : Tag(id: "", name: "", nameEn: "", color: "#999", createdAt: DateTime.now()),
                    );
                    final name = isZh
                        ? tag.name
                        : (tag.nameEn.isNotEmpty ? tag.nameEn : tag.name);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _niceInterval(maxCount),
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: topTags.asMap().entries.map((e) {
            final tag = tagProvider.tags.firstWhere(
              (t) => t.id == e.value.tagId,
              orElse: () => tagProvider.tags.isNotEmpty ? tagProvider.tags.first : Tag(id: "", name: "", nameEn: "", color: "#999", createdAt: DateTime.now()),
            );
            final color = _parseHexColor(tag.color);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  color: color,
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

Color _parseHexColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

class _WritingStatsSection extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;

  const _WritingStatsSection({required this.summary, required this.isZh});

  static const _weekdayLabelsEn = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _weekdayLabelsZh = [
    '',
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  @override
  Widget build(BuildContext context) {
    final avgWords = summary.averageEntryLength;
    final activeDay = summary.mostActiveDayOfWeek;
    final activeHour = summary.mostActiveHour;

    return SizedBox(height: 110, child: Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.text_fields,
            value: avgWords.toStringAsFixed(1),
            label: isZh ? '平均字数' : 'avg words',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.calendar_today,
            value: activeDay != null
                ? (isZh
                    ? _weekdayLabelsZh[activeDay]
                    : _weekdayLabelsEn[activeDay].substring(0, 3))
                : '---',
            label: isZh ? '最活跃日' : 'most active',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.schedule,
            value: activeHour != null ? '$activeHour:00' : '---',
            label: isZh ? '最活跃时段' : 'peak hour',
          ),
        ),
      ],
    ));
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistInsightsSection extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;

  const _ChecklistInsightsSection({required this.summary, required this.isZh});

  @override
  Widget build(BuildContext context) {
    final totalLists = summary.totalLists;
    final completionRate = summary.checklistCompletionRate;
    final carriedForward = summary.totalCarriedForward;
    final topItem = summary.topChecklistItem;

    if (totalLists == 0) {
      return _ChecklistInsightsEmpty(isZh: isZh);
    }

    return Column(
      children: [
        _ChecklistStatRow(
          icon: Icons.list_alt,
          value: '$totalLists',
          label: isZh ? '已创建清单' : 'lists created',
        ),
        const SizedBox(height: 10),
        _ChecklistStatRow(
          icon: Icons.check_circle_outline,
          value: '${(completionRate * 100).round()}%',
          label: isZh ? '平均完成率' : 'avg completion',
        ),
        const SizedBox(height: 10),
        _ChecklistStatRow(
          icon: Icons.replay,
          value: '$carriedForward',
          label: isZh ? '已结转事项' : 'carried forward',
        ),
        if (topItem != null) ...[
          const SizedBox(height: 10),
          _ChecklistStatRow(
            icon: Icons.push_pin,
            value: '"${topItem.text}"',
            label: '${isZh ? '最常见事项' : 'top item'} (${topItem.count}×)',
          ),
        ],
      ],
    );
  }
}

class _ChecklistStatRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ChecklistStatRow({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 13,
              ),
        ),
      ],
    );
  }
}

class _ChecklistInsightsEmpty extends StatelessWidget {
  final bool isZh;
  const _ChecklistInsightsEmpty({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          isZh ? '创建清单即可查看洞察' : 'Create checklists to see insights',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}

class _TagMoodSection extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;

  const _TagMoodSection({required this.summary, required this.isZh});

  static const _moodEmojis = ['😡', '😡', '😢', '😐', '😌', '😊'];
  static const _moodColors = {
    1: Color(0xFFE76F51),
    2: Color(0xFF457B9D),
    3: Color(0xFFE9C46A),
    4: Color(0xFFA8DADC),
    5: Color(0xFF10317D),
  };

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final correlations = summary.tagMoodCorrelation;

    if (correlations.isEmpty) {
      return _TagMoodEmpty(isZh: isZh);
    }

    return Column(
      children: [
        ...correlations.take(5).map((c) {
          final tag = tagProvider.tags.firstWhere(
            (t) => t.id == c.tagId,
            orElse: () => tagProvider.tags.isNotEmpty ? tagProvider.tags.first : Tag(id: "", name: "", nameEn: "", color: "#999", createdAt: DateTime.now()),
          );
          final name = isZh
              ? tag.name
              : (tag.nameEn.isNotEmpty ? tag.nameEn : tag.name);
          final idx = c.avgScore.round().clamp(1, 5);
          final emoji = _moodEmojis[idx];
          final color = _moodColors[idx] ?? Colors.grey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c.avgScore / 5.0,
                      minHeight: 14,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${c.avgScore.toStringAsFixed(1)}/5',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          isZh ? '显示出现 3 次以上的标签' : 'Tags with ≥3 entries shown',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}

class _TagMoodEmpty extends StatelessWidget {
  final bool isZh;
  const _TagMoodEmpty({required this.isZh});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          isZh ? '需要更多带标签和情绪的记录' : 'Need more entries with tags & emotions',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          isZh ? '暂无数据' : 'No data yet',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}

/// Returns a nice interval for y-axis labels (1, 2, 5, 10, 20, 50, ...)
double _niceInterval(num maxY) {
  if (maxY <= 0) return 1;
  final magnitude = maxY / 5.0;
  final expStr = magnitude.toInt().toString();
  final e = expStr.length - 1;
  final p10 = e > 0 ? double.parse('1${List.filled(e, '0').join()}') : 1.0;
  final normalized = magnitude / p10;
  double nice;
  if (normalized <= 1.5) {
    nice = 1;
  } else if (normalized <= 3) {
    nice = 2;
  } else if (normalized <= 7) {
    nice = 5;
  } else {
    nice = 10;
  }
    return (nice * p10).ceilToDouble();
}

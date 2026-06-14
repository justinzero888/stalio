import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/summary_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../providers/tag_category_provider.dart';
import '../../../models/tag.dart';

class TagAnalyticsTab extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;

  const TagAnalyticsTab({required this.summary, required this.isZh, super.key});

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final categoryProvider = context.watch<TagCategoryProvider>();
    final tags = tagProvider.tags;
    final categories = categoryProvider.categories;

    if (tags.isEmpty) {
      return Center(
        child: Text(isZh ? '暂无标签数据' : 'No tag data yet',
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      );
    }

    final usage = _buildUsageMap(tags);
    final topTags = usage.entries
        .where((e) => e.key.category != 'system')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top10 = topTags.take(10).toList();
    final coPairs = _buildCoOccurrence(tags, top10.map((e) => e.key.id).toList());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (top10.isNotEmpty) ...[
          _sectionTitle(isZh ? '标签使用排行' : 'Top Tags', context),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (top10.first.value * 1.2).ceilToDouble(),
                barGroups: List.generate(top10.length, (i) {
                  final tag = top10[i];
                  final catColor = categories
                      .where((c) => c.id == tag.key.categoryId)
                      .map((c) => Color(int.parse(c.color.replaceFirst('#', '0xFF'))))
                      .toList();
                  final barColor = catColor.isNotEmpty
                      ? catColor.first
                      : Color(int.parse(tag.key.color.replaceFirst('#', '0xFF')));
                  return BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(toY: tag.value.toDouble(), color: barColor, width: 20)],
                  );
                }),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top10.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(top10[idx].key.displayName(isZh),
                              style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (coPairs.isNotEmpty) ...[
          _sectionTitle(isZh ? '标签共现' : 'Co-occurrence', context),
          const SizedBox(height: 8),
          for (final pair in coPairs)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tagDot(pair.tagA.color),
                    const SizedBox(width: 4),
                    Text(pair.tagA.displayName(isZh), style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    const Icon(Icons.sync_alt, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    _tagDot(pair.tagB.color),
                    const SizedBox(width: 4),
                    Text(pair.tagB.displayName(isZh), style: const TextStyle(fontSize: 13)),
                  ],
                ),
                trailing: Text('${pair.count}x', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 24),
        ],
        _sectionTitle(isZh ? '标签使用时间线' : 'Usage Timeline', context),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: _TimelineChart(usage: usage, isZh: isZh),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text, BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600));
  }

  Widget _tagDot(String color) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
      ),
    );
  }

  Map<Tag, int> _buildUsageMap(List<Tag> tags) {
    final map = <Tag, int>{};
    for (final tag in tags) {
      map[tag] = summary.tagUsageCount(tag.id);
    }
    return map;
  }

  List<_CoPair> _buildCoOccurrence(List<Tag> tags, List<String> topIds) {
    final pairs = <String, _CoPair>{};
    final topTagMap = {for (final t in tags.where((t) => topIds.contains(t.id))) t.id: t};
    for (final entry in summary.getEntriesWithTags()) {
      final tagIds = entry.tagIds.where((id) => topTagMap.containsKey(id)).toList();
      for (int i = 0; i < tagIds.length; i++) {
        for (int j = i + 1; j < tagIds.length; j++) {
          final ids = [tagIds[i], tagIds[j]]..sort();
          final key = '${ids[0]}_${ids[1]}';
          pairs.putIfAbsent(key, () => _CoPair(
            tagA: topTagMap[ids[0]]!,
            tagB: topTagMap[ids[1]]!,
            count: 0,
          ));
          pairs[key] = pairs[key]!.copyWith(count: pairs[key]!.count + 1);
        }
      }
    }
    final sorted = pairs.values.toList()..sort((a, b) => b.count.compareTo(a.count));
    return sorted.take(10).toList();
  }
}

class _CoPair {
  final Tag tagA;
  final Tag tagB;
  final int count;
  _CoPair({required this.tagA, required this.tagB, required this.count});
  _CoPair copyWith({int? count}) => _CoPair(tagA: tagA, tagB: tagB, count: count ?? this.count);
}

class _TimelineChart extends StatelessWidget {
  final Map<Tag, int> usage;
  final bool isZh;
  const _TimelineChart({required this.usage, required this.isZh});

  @override
  Widget build(BuildContext context) {
    final top5 = usage.entries
        .where((e) => e.key.category != 'system')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = top5.take(5).toList();
    if (top.isEmpty) return const SizedBox();

    return LineChart(
      LineChartData(
        lineBarsData: List.generate(top.length, (i) {
          return LineChartBarData(
            spots: [FlSpot(0, 0), FlSpot(1, top[i].value.toDouble())],
            isCurved: true,
            color: Color(int.parse(top[i].key.color.replaceFirst('#', '0xFF'))),
            barWidth: 2,
            dotData: FlDotData(show: true),
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                if (v == 0) return Text(isZh ? '开始' : 'Start', style: const TextStyle(fontSize: 10));
                if (v == 1) return Text(isZh ? '现在' : 'Now', style: const TextStyle(fontSize: 10));
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

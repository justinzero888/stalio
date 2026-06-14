import 'package:flutter/material.dart';
import '../../providers/summary_provider.dart';
import '../../l10n/app_localizations.dart';

class NotesTab extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;
  const NotesTab({required this.summary, required this.isZh, super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _SectionTitle(title: isZh ? '写作统计' : 'Writing Stats'),
      _WritingStatsSection(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: isZh ? '笔记数量' : 'Note Count'),
      _NoteCountChart(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: isZh ? '热门标签' : 'Top Tags'),
      _TopTagsChart(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: 'Checklists'),
      _ChecklistInsightsSection(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: isZh ? '标签心情' : 'Tag Mood'),
      _TagMoodSection(summary: summary, isZh: isZh),
    ]);
  }
}

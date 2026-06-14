import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../providers/summary_provider.dart';
import '../../providers/jar_provider.dart';
import '../../widgets/emoji_jar.dart';
import '../../l10n/app_localizations.dart';

class MoodsTab extends StatelessWidget {
  final SummaryProvider summary;
  final List<int> years;
  final bool isZh;
  const MoodsTab({required this.summary, required this.years, required this.isZh, super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _SectionTitle(title: isZh ? '心情分布' : 'Mood Distribution'),
      _MoodDistributionChart(summary: summary, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: isZh ? '情绪趋势' : 'Emotion Trend'),
      _EmotionTrendChart(summary: summary, years: years, isZh: isZh),
      const SizedBox(height: 24),
      _SectionTitle(title: isZh ? '心情罐子' : 'Emoji Jar'),
      SizedBox(height: 200, child: EmojiJarWidget(years: years)),
    ]);
  }
}

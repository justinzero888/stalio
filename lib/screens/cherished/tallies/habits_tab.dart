import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/routine_provider.dart';
import '../../l10n/app_localizations.dart';

class HabitsTab extends StatelessWidget {
  final SummaryProvider summary;
  final bool isZh;
  const HabitsTab({required this.summary, required this.isZh, super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RoutineProvider>();
    final active = p.routines.where((r) => r.isActive).toList();
    if (active.isEmpty) return const _EmptyChart(message: 'No active habits');
    final total = active.length;
    final done = active.where((r) => p.isCompletedToday(r)).length;
    final best = active.fold<int>(0, (m, r) => r.streak > m ? r.streak : m);
    return ListView(padding: const EdgeInsets.all(16), children: [
      _SectionTitle(title: 'Completion'),
      _RoutineCompletionChart(routines: active, isZh: isZh, summary: summary),
      const SizedBox(height: 16),
      _StreakMatrixSection(routines: active, isZh: isZh),
    ]);
  }
}

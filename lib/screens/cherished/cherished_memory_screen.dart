import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/entry_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/locale_provider.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Scaffold(
      appBar: AppBar(title: Text(isZh ? '洞察' : 'Insights')),
      body: Consumer2<EntryProvider, RoutineProvider>(
        builder: (context, entryProvider, routineProvider, _) {
          final totalEntries = entryProvider.allEntries.length;
          final activeHabits = routineProvider.activeRoutines.length;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insights, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  isZh ? '总计笔记: $totalEntries' : 'Total Notes: $totalEntries',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh ? '活跃习惯: $activeHabits' : 'Active Habits: $activeHabits',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/routine.dart';
import '../providers/locale_provider.dart';

/// Widget for displaying a routine item in the routine dashboard
class RoutineItem extends StatelessWidget {
  final Routine routine;
  final bool isCompletedToday;
  final int? todayValue;
  final VoidCallback? onComplete;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePause;

  const RoutineItem({
    super.key,
    required this.routine,
    required this.isCompletedToday,
    this.todayValue,
    this.onComplete,
    this.onIncrement,
    this.onDecrement,
    this.onTap,
    this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    final active = routine.isActive;
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildLeading(context),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    routine.displayName(isZh),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: active ? null : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSubtitle(context, isZh),
                if (!active)
                  IconButton(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    onPressed: onTogglePause,
                    tooltip: isZh ? '恢复' : 'Resume',
                    color: Colors.grey[400],
                  ),
                if (active)
                  Checkbox(
                    value: isCompletedToday,
                    onChanged: (_) => onComplete?.call(),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (routine.iconImagePath != null && routine.iconImagePath!.isNotEmpty) {
      final file = File(routine.iconImagePath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 36, height: 36, fit: BoxFit.cover),
        );
      }
    }
    return Text(
      routine.icon ?? routine.effectiveIcon,
      style: const TextStyle(fontSize: 22),
    );
  }

  Widget _buildSubtitle(BuildContext context, bool isZh) {
    if (!routine.isActive) {
      return Text(
        isZh ? '已暂停' : 'Paused',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }

    if (routine.targetCount != null && todayValue != null) {
      return Row(
        children: [
          Text(
            '${isZh ? '今日' : 'Today'}: $todayValue',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            ' / ${routine.targetCount}',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      );
    }

    if (routine.streak > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            isZh ? '${routine.streak} 天连续' : '${routine.streak} day streak',
            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
          ),
        ],
      );
    }

    return Text(
      routine.frequencyLabelFor(isZh),
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    );
  }
}

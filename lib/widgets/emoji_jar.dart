import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class EmojiJarWidget extends StatelessWidget {
  final DateTime date;
  final bool canUseAI;
  final bool isToday;
  final List<Map<String, String>> existingReflections;
  final VoidCallback? onReflectionSaved;
  final double? size;
  final List<String>? emotionsOverride;

  const EmojiJarWidget({
    super.key,
    required this.date,
    required this.canUseAI,
    required this.isToday,
    required this.existingReflections,
    this.onReflectionSaved,
    this.size,
    this.emotionsOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isZh = context.watch<LocaleProvider>().locale.languageCode == 'zh';
    return Center(
      child: Text(
        isZh ? '心情罐' : 'Emotion Jar',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

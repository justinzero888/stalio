import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../providers/locale_provider.dart';

/// Helper to convert hex string to Color
Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse(hex, radix: 16));
}

/// Chip widget for displaying a tag
class TagChip extends StatelessWidget {
  final Tag tag;
  final bool small;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TagChip({
    super.key,
    required this.tag,
    this.small = false,
    this.selected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(tag.color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 12,
          vertical: small ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha(77)
              : color.withAlpha(26),
          borderRadius: BorderRadius.circular(small ? 12 : 16),
          border: Border.all(
            color: selected ? color : color.withAlpha(128),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check,
                  size: small ? 12 : 14,
                  color: color,
                ),
              ),
            Text(
              tag.displayName(
                context.read<LocaleProvider>().locale.languageCode == 'zh',
              ),
              style: TextStyle(
                fontSize: small ? 11 : 13,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close,
                    size: small ? 12 : 14,
                    color: color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple tag chip with just name and color string (for display)
class SimpleTagChip extends StatelessWidget {
  final String name;
  final Color color;
  final bool small;

  const SimpleTagChip({
    super.key,
    required this.name,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(small ? 12 : 16),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: small ? 11 : 13,
          color: color,
        ),
      ),
    );
  }
}

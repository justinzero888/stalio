import 'reflection_style.dart';

class LensSet {
  final String id;
  final String label;
  final String lens1;
  final String lens2;
  final String lens3;
  final bool isBuiltin;
  final int sortOrder;
  final DateTime createdAt;

  LensSet({
    required this.id,
    required this.label,
    required this.lens1,
    required this.lens2,
    required this.lens3,
    this.isBuiltin = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  List<String> get lenses => [lens1, lens2, lens3];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'lens_1': lens1,
      'lens_2': lens2,
      'lens_3': lens3,
      'is_builtin': isBuiltin ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LensSet.fromJson(Map<String, dynamic> json) {
    return LensSet(
      id: json['id'] as String,
      label: json['label'] as String,
      lens1: json['lens_1'] as String,
      lens2: json['lens_2'] as String,
      lens3: json['lens_3'] as String,
      isBuiltin: (json['is_builtin'] as int? ?? 0) == 1,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt:
          DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class DefaultLensSets {
  /// Built-in lens sets matching the 4 persona presets.
  static List<LensSet> defaults(bool isZh) {
    final styles = ReflectionStyle.presets;
    return styles.map((s) {
      final lenses = s.lenses(isZh);
      return LensSet(
        id: 'lens_style_${s.id}',
        label: isZh ? '${s.nameZh} — ${s.vibeZh}' : '${s.name} — ${s.vibeEn}',
        lens1: lenses[0],
        lens2: lenses[1],
        lens3: lenses[2],
        isBuiltin: true,
        sortOrder: styles.indexOf(s) + 1,
        createdAt: DateTime(2026, 1, 1),
      );
    }).toList();
  }

  static const String defaultActiveSetId = 'lens_style_kael';
}

/// TagCategory model — groups tags under named categories
class TagCategory {
  final String id;
  final String name;
  final String nameEn;
  final String color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;

  TagCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    this.icon = '📁',
    this.sortOrder = 0,
    required this.createdAt,
  });

  TagCategory copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TagCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String displayName(bool isZh) => isZh ? name : nameEn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'color': color,
      'icon': icon,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TagCategory.fromJson(Map<String, dynamic> json) {
    return TagCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String? ?? '📁',
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

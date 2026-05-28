/// A folder for organizing note cards
class CardFolder {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;

  String displayNameFor(bool isZh) {
    if (!isZh && id == 'folder_default') return 'My Cards';
    return name;
  }

  const CardFolder({
    required this.id,
    required this.name,
    required this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  CardFolder copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CardFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'is_default': isDefault ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory CardFolder.fromJson(Map<String, dynamic> json) => CardFolder(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        isDefault: (json['is_default'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

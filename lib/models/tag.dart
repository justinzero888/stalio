/// Tag model - for categorizing entries
class Tag {
  final String id;
  final String name;
  final String nameEn; // English name
  final String color; // Hex color string (e.g., "#FF5500")
  final String category; // Custom category
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    this.category = 'custom',
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? color,
    String? category,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      color: color ?? this.color,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the display name for the current locale.
  String displayName(bool isZh) => isZh ? name : nameEn;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'color': color,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      color: json['color'] as String,
      category: json['category'] as String? ?? 'custom',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Default tags for new users
class DefaultTags {
  static List<Tag> get defaults => [
    Tag(id: 'tag_family', name: '家人', nameEn: 'Family', color: '#FF9500', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_insight', name: '领悟', nameEn: 'Insight', color: '#5856D6', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_gratitude', name: '感恩', nameEn: 'Gratitude', color: '#FF2D55', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_daily', name: '日常', nameEn: 'Daily', color: '#007AFF', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_wellness', name: '养生', nameEn: 'Wellness', color: '#34C759', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_learning', name: '学习', nameEn: 'Learning', color: '#AF52DE', category: 'custom', createdAt: DateTime.now()),
    Tag(id: 'tag_synthesis', name: 'AI综整', nameEn: 'AI Synthesis', color: '#AF52DE', category: 'system', createdAt: DateTime.now()),
    Tag(id: 'tag_private', name: '私密', nameEn: 'Private', color: '#9E9E9E', category: 'system', createdAt: DateTime.now()),
    Tag(id: 'tag_welcome', name: '欢迎', nameEn: 'Welcome', color: '#34C759', category: 'system', createdAt: DateTime.now()),
  ];
}

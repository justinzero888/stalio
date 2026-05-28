class AiIdentity {
  final String avatarEmoji;
  final String? avatarImagePath;
  final String assistantName;
  final String personalityString;
  final DateTime updatedAt;

  AiIdentity({
    this.avatarEmoji = '\u2726',
    this.avatarImagePath,
    this.assistantName = 'Companion',
    this.personalityString = 'Warm and grounded.',
    required this.updatedAt,
  });

  AiIdentity copyWith({
    String? avatarEmoji,
    String? avatarImagePath,
    String? assistantName,
    String? personalityString,
    DateTime? updatedAt,
  }) {
    return AiIdentity(
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarImagePath: avatarImagePath ?? this.avatarImagePath,
      assistantName: assistantName ?? this.assistantName,
      personalityString: personalityString ?? this.personalityString,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar_emoji': avatarEmoji,
      'avatar_image_path': avatarImagePath,
      'assistant_name': assistantName,
      'personality_string': personalityString,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AiIdentity.fromJson(Map<String, dynamic> json) {
    return AiIdentity(
      avatarEmoji: json['avatar_emoji'] as String? ?? '\u2726',
      avatarImagePath: json['avatar_image_path'] as String?,
      assistantName: json['assistant_name'] as String? ?? 'Companion',
      personalityString:
          json['personality_string'] as String? ?? 'Warm and grounded.',
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

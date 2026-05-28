class AiCallLog {
  final String id;
  final String surface;
  final DateTime calledAt;
  final String? moodLogId;
  final bool kept;

  AiCallLog({
    required this.id,
    required this.surface,
    required this.calledAt,
    this.moodLogId,
    this.kept = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surface': surface,
      'called_at': calledAt.toIso8601String(),
      'mood_log_id': moodLogId,
      'kept': kept ? 1 : 0,
    };
  }

  factory AiCallLog.fromJson(Map<String, dynamic> json) {
    return AiCallLog(
      id: json['id'] as String,
      surface: json['surface'] as String,
      calledAt: DateTime.parse(json['called_at'] as String),
      moodLogId: json['mood_log_id'] as String?,
      kept: (json['kept'] as int? ?? 0) == 1,
    );
  }
}

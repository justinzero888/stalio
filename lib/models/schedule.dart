/// Schedule model - represents a planned routine execution for a specific date
class Schedule {
  final String id;
  final String routineId;
  final DateTime scheduledDate;
  final DateTime? completedAt;
  final String? notes;

  Schedule({
    required this.id,
    required this.routineId,
    required this.scheduledDate,
    this.completedAt,
    this.notes,
  });

  bool get isCompleted => completedAt != null;

  Schedule copyWith({
    String? id,
    String? routineId,
    DateTime? scheduledDate,
    DateTime? completedAt,
    String? notes,
  }) {
    return Schedule(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

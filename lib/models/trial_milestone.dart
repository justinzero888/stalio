class TrialMilestone {
  final String milestone;
  final DateTime? shownAt;

  TrialMilestone({
    required this.milestone,
    this.shownAt,
  });

  bool get wasShown => shownAt != null;

  Map<String, dynamic> toJson() {
    return {
      'milestone': milestone,
      'shown_at': shownAt?.toIso8601String(),
    };
  }

  factory TrialMilestone.fromJson(Map<String, dynamic> json) {
    return TrialMilestone(
      milestone: json['milestone'] as String,
      shownAt: json['shown_at'] != null
          ? DateTime.parse(json['shown_at'] as String)
          : null,
    );
  }
}

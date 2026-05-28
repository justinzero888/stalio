// lib/models/media.dart

enum MediaType { text, audio, video, image }

class Media {
  final String id;
  final String entryId;
  final MediaType type;
  final String? localPath;
  final String? cloudUrl;
  final DateTime createdAt;

  Media({
    required this.id,
    required this.entryId,
    required this.type,
    this.localPath,
    this.cloudUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      entryId: json['entryId'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.text,
      ),
      localPath: json['localPath'] as String?,
      cloudUrl: json['cloudUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entryId': entryId,
      'type': type.name,
      'localPath': localPath,
      'cloudUrl': cloudUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayUrl => localPath ?? cloudUrl ?? '';
}
import 'list_item.dart';

export 'list_item.dart';

/// Entry type enum
enum EntryType {
  routine,
  freeform,
}

/// Format of the entry content (note or checklist)
enum EntryFormat {
  note,
  list,
}

/// Entry model - represents a memory entry (freeform or routine)
class Entry {
  final String id;
  final EntryType type;
  final String content;
  final List<String> tagIds;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final String? emotion;
  final EntryFormat format;
  final List<ListItem>? listItems;
  final bool listCarriedForward;

  Entry({
    required this.id,
    required this.type,
    required this.content,
    this.tagIds = const [],
    this.mediaUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.emotion,
    this.format = EntryFormat.note,
    this.listItems,
    this.listCarriedForward = false,
  });

  Entry copyWith({
    String? id,
    EntryType? type,
    String? content,
    List<String>? tagIds,
    List<String>? mediaUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? emotion,
    bool clearEmotion = false,
    EntryFormat? format,
    List<ListItem>? listItems,
    bool clearListItems = false,
    bool? listCarriedForward,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      tagIds: tagIds ?? this.tagIds,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      format: format ?? this.format,
      listItems: clearListItems ? null : (listItems ?? this.listItems),
      listCarriedForward: listCarriedForward ?? this.listCarriedForward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'tagIds': tagIds,
      'mediaUrls': mediaUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
      'emotion': emotion,
      'format': format.name,
      'listItems': ListItem.listToJson(listItems),
      'listCarriedForward': listCarriedForward,
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String,
      type: EntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntryType.freeform,
      ),
      content: json['content'] as String,
      tagIds: List<String>.from(json['tagIds'] ?? []),
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      emotion: json['emotion'] as String?,
      format: _parseFormat(json['format']),
      listItems: json['listItems'] != null
          ? ListItem.listFromJson(json['listItems'] as String?)
          : null,
      listCarriedForward: json['listCarriedForward'] as bool? ?? false,
    );
  }

  static EntryFormat _parseFormat(dynamic value) {
    if (value == null) return EntryFormat.note;
    if (value is String) {
      return EntryFormat.values.firstWhere(
        (e) => e.name == value,
        orElse: () => EntryFormat.note,
      );
    }
    return EntryFormat.note;
  }
}

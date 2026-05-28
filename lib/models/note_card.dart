import 'dart:convert';

/// A rendered note card linking entries to a template and folder
class NoteCard {
  final String id;
  final List<String> entryIds;
  final String templateId;
  final String folderId;
  final String? renderedImagePath;
  final String? aiSummary;
  final String? richContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  // v1.2.0 new fields
  final String? cardContent; // final text displayed on card (post-edit)
  final String? emotion; // emoji shown on card
  final List<String>? displayTags; // tags shown as hashtags on card
  final bool showMood;
  final bool showDate;
  final bool showTags;
  final bool showFooter;
  final String? templateOverrides; // JSON for user style overrides

  const NoteCard({
    required this.id,
    required this.entryIds,
    required this.templateId,
    required this.folderId,
    this.renderedImagePath,
    this.aiSummary,
    this.richContent,
    required this.createdAt,
    required this.updatedAt,
    this.cardContent,
    this.emotion,
    this.displayTags,
    this.showMood = true,
    this.showDate = true,
    this.showTags = true,
    this.showFooter = true,
    this.templateOverrides,
  });

  NoteCard copyWith({
    String? id,
    List<String>? entryIds,
    String? templateId,
    String? folderId,
    String? renderedImagePath,
    bool clearImagePath = false,
    String? aiSummary,
    String? richContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cardContent,
    bool clearCardContent = false,
    String? emotion,
    bool clearEmotion = false,
    List<String>? displayTags,
    bool clearDisplayTags = false,
    bool? showMood,
    bool? showDate,
    bool? showTags,
    bool? showFooter,
    String? templateOverrides,
    bool clearTemplateOverrides = false,
  }) {
    return NoteCard(
      id: id ?? this.id,
      entryIds: entryIds ?? this.entryIds,
      templateId: templateId ?? this.templateId,
      folderId: folderId ?? this.folderId,
      renderedImagePath:
          clearImagePath ? null : (renderedImagePath ?? this.renderedImagePath),
      aiSummary: aiSummary ?? this.aiSummary,
      richContent: richContent ?? this.richContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardContent:
          clearCardContent ? null : (cardContent ?? this.cardContent),
      emotion: clearEmotion ? null : (emotion ?? this.emotion),
      displayTags:
          clearDisplayTags ? null : (displayTags ?? this.displayTags),
      showMood: showMood ?? this.showMood,
      showDate: showDate ?? this.showDate,
      showTags: showTags ?? this.showTags,
      showFooter: showFooter ?? this.showFooter,
      templateOverrides: clearTemplateOverrides
          ? null
          : (templateOverrides ?? this.templateOverrides),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entry_ids': entryIds,
        'template_id': templateId,
        'folder_id': folderId,
        'rendered_image_path': renderedImagePath,
        'ai_summary': aiSummary,
        'rich_content': richContent,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'card_content': cardContent,
        'emotion': emotion,
        'display_tags': displayTags,
        'show_mood': showMood ? 1 : 0,
        'show_date': showDate ? 1 : 0,
        'show_tags': showTags ? 1 : 0,
        'show_footer': showFooter ? 1 : 0,
        'template_overrides': templateOverrides,
      };

  factory NoteCard.fromJson(Map<String, dynamic> json) => NoteCard(
        id: json['id'] as String,
        entryIds: List<String>.from(json['entry_ids'] as List? ?? []),
        templateId: json['template_id'] as String,
        folderId: json['folder_id'] as String,
        renderedImagePath: json['rendered_image_path'] as String?,
        aiSummary: json['ai_summary'] as String?,
        richContent: json['rich_content'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        cardContent: json['card_content'] as String?,
        emotion: json['emotion'] as String?,
        displayTags: _parseTagList(json['display_tags']),
        showMood: (json['show_mood'] as int? ?? 1) == 1,
        showDate: (json['show_date'] as int? ?? 1) == 1,
        showTags: (json['show_tags'] as int? ?? 1) == 1,
        showFooter: (json['show_footer'] as int? ?? 1) == 1,
        templateOverrides: json['template_overrides'] as String?,
      );

  static List<String>? _parseTagList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value);
    if (value is String) {
      try {
        return List<String>.from(jsonDecode(value) as List);
      } catch (_) {}
    }
    return null;
  }
}

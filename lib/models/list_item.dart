import 'dart:convert';

class ListItem {
  final String id;
  final String text;
  final bool isDone;
  final int sortOrder;
  final bool fromPreviousDay;

  ListItem({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.sortOrder,
    this.fromPreviousDay = false,
  }) : assert(text.isNotEmpty, 'ListItem text must not be empty'),
       assert(text.length <= 200, 'ListItem text must be <= 200 chars');

  ListItem copyWith({
    String? id,
    String? text,
    bool? isDone,
    int? sortOrder,
    bool? fromPreviousDay,
  }) {
    return ListItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
      fromPreviousDay: fromPreviousDay ?? this.fromPreviousDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'is_done': isDone,
        'sort_order': sortOrder,
        'from_previous_day': fromPreviousDay,
      };

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
        id: json['id'] as String,
        text: json['text'] as String,
        isDone: json['is_done'] as bool? ?? false,
        sortOrder: json['sort_order'] as int? ?? 0,
        fromPreviousDay: json['from_previous_day'] as bool? ?? false,
      );

  static List<ListItem> listFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => ListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String? listToJson(List<ListItem>? items) {
    if (items == null || items.isEmpty) return null;
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItem &&
          id == other.id &&
          text == other.text &&
          isDone == other.isDone &&
          sortOrder == other.sortOrder &&
          fromPreviousDay == other.fromPreviousDay;

  @override
  int get hashCode => Object.hash(id, text, isDone, sortOrder, fromPreviousDay);

  @override
  String toString() => 'ListItem(id: $id, text: $text, isDone: $isDone, sortOrder: $sortOrder, fromPreviousDay: $fromPreviousDay)';
}

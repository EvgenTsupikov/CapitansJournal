// lib/models/quest_checklist_item.dart
class QuestChecklistItem {
  final String id;
  String text;
  bool isCompleted;

  QuestChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCompleted': isCompleted,
      };

  factory QuestChecklistItem.fromJson(Map<String, dynamic> json) =>
      QuestChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  QuestChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return QuestChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}


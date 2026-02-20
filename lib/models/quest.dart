// lib/models/quest.dart
import 'quest_checklist_item.dart';

enum QuestPriority {
  low,
  medium,
  high,
}

class Quest {
  final String id;
  String title;
  QuestPriority priority;
  String notes;
  List<QuestChecklistItem> checklist;
  final String folderId; // ID папки, к которой принадлежит квест
  final DateTime createdAt;
  DateTime? updatedAt;

  Quest({
    required this.id,
    required this.title,
    this.priority = QuestPriority.medium,
    this.notes = '',
    this.checklist = const [],
    required this.folderId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'notes': notes,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'folderId': folderId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Quest.fromJson(Map<String, dynamic> json) {
    final priorityString = json['priority'] as String? ?? 'medium';
    QuestPriority priority;
    switch (priorityString) {
      case 'high':
        priority = QuestPriority.high;
        break;
      case 'low':
        priority = QuestPriority.low;
        break;
      case 'medium':
      default:
        priority = QuestPriority.medium;
        break;
    }

    return Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      priority: priority,
      notes: json['notes'] as String? ?? '',
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => QuestChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      folderId: json['folderId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Quest copyWith({
    String? id,
    String? title,
    QuestPriority? priority,
    String? notes,
    List<QuestChecklistItem>? checklist,
    String? folderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      checklist: checklist ?? this.checklist,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Получает процент выполнения чеклиста
  double get checklistProgress {
    if (checklist.isEmpty) return 0.0;
    final completed = checklist.where((item) => item.isCompleted).length;
    return completed / checklist.length;
  }
}


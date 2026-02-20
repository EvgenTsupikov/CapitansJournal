// lib/models/action_log.dart
class ActionLog {
  final String id;
  final String action; // 'create', 'edit', 'delete', 'restore', 'change_date', 'change_time'
  final String noteText;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // Дополнительная информация

  ActionLog({
    required this.id,
    required this.action,
    required this.noteText,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'noteText': noteText,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory ActionLog.fromJson(Map<String, dynamic> json) => ActionLog(
    id: json['id'],
    action: json['action'],
    noteText: json['noteText'],
    timestamp: DateTime.parse(json['timestamp']),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  String get actionName {
    switch (action) {
      case 'create':
        return 'Создание';
      case 'edit':
        return 'Редактирование';
      case 'delete':
        return 'Удаление';
      case 'restore':
        return 'Восстановление';
      case 'change_date':
        return 'Изменение даты';
      case 'change_time':
        return 'Изменение времени';
      default:
        return action;
    }
  }

  String get actionNameEn {
    switch (action) {
      case 'create':
        return 'Created';
      case 'edit':
        return 'Edited';
      case 'delete':
        return 'Deleted';
      case 'restore':
        return 'Restored';
      case 'change_date':
        return 'Date Changed';
      case 'change_time':
        return 'Time Changed';
      default:
        return action;
    }
  }
}


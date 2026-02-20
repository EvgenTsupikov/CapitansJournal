// lib/models/deleted_note.dart
import 'note.dart';

class DeletedNote {
  final Note note;
  final DateTime deletedAt;

  DeletedNote({
    required this.note,
    required this.deletedAt,
  });

  Map<String, dynamic> toJson() => {
    'note': note.toJson(),
    'deletedAt': deletedAt.toIso8601String(),
  };

  factory DeletedNote.fromJson(Map<String, dynamic> json) => DeletedNote(
    note: Note.fromJson(json['note']),
    deletedAt: DateTime.parse(json['deletedAt']),
  );

  int get daysUntilPermanentDelete {
    final daysSinceDeletion = DateTime.now().difference(deletedAt).inDays;
    return (30 - daysSinceDeletion).clamp(0, 30);
  }

  bool get shouldBeDeleted {
    return DateTime.now().difference(deletedAt).inDays >= 30;
  }
}


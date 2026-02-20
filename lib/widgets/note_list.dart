import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final void Function(int) onDelete;
  final void Function(int) onEdit;

  const NoteList({
    super.key,
    required this.notes,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Center(child: Text('Список пуст'));
    }
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          child: ListTile(
            title: Text(note.text),
            subtitle: Text(
              '${note.createdAt.day.toString().padLeft(2,'0')}.'
                  '${note.createdAt.month.toString().padLeft(2,'0')}.'
                  '${note.createdAt.year} '
                  '${note.createdAt.hour.toString().padLeft(2,'0')}:'
                  '${note.createdAt.minute.toString().padLeft(2,'0')}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

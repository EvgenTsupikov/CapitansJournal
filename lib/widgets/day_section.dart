import 'package:flutter/material.dart';
import '../models/note.dart';

class DaySection extends StatefulWidget {
  final String dateKey;
  final List<Note> notes;

  final Future<void> Function(String dateKey) onCopy;
  final int Function(String dateKey, int indexInDay) flatIndexFor;
  final void Function(int flatIndex) onEdit;
  final void Function(int flatIndex) onDelete;

  final String Function(String key) formatDate;
  final String Function(DateTime dt) formatTime;

  const DaySection({
    super.key,
    required this.dateKey,
    required this.notes,
    required this.onCopy,
    required this.flatIndexFor,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  State<DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<DaySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────────────────────────────────────────
            // Заголовок дня (дата + иконка копирования + стрелка)
            // ──────────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  // дата
                  Text(
                    widget.formatDate(widget.dateKey),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // иконка "копировать"
                  IconButton(
                    onPressed: () => widget.onCopy(widget.dateKey),
                    icon: const Icon(Icons.copy, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: "Скопировать все записи дня",
                  ),

                  const SizedBox(width: 12),

                  // стрелка
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 26,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ──────────────────────────────────────────────
            // Список заметок
            // ──────────────────────────────────────────────
            if (_expanded)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.notes.length,
                itemBuilder: (context, i) {
                  final n = widget.notes[i];

                  return GestureDetector(
                    onLongPress: () {
                      final flat = widget.flatIndexFor(widget.dateKey, i);

                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text("Редактировать"),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onEdit(flat);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text("Удалить"),
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.onDelete(flat);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // время маленьким текстом
                          Text(
                            widget.formatTime(n.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // текст заметки
                          Text(
                            n.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

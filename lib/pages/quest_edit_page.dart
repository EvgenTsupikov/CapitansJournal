// lib/pages/quest_edit_page.dart
import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../models/quest_checklist_item.dart';
import '../l10n/app_localizations.dart';
import 'dart:math';

class QuestEditPage extends StatefulWidget {
  final Quest quest;

  const QuestEditPage({
    super.key,
    required this.quest,
  });

  @override
  State<QuestEditPage> createState() => _QuestEditPageState();
}

class _QuestEditPageState extends State<QuestEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late QuestPriority _priority;
  late List<QuestChecklistItem> _checklist;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quest.title);
    _notesController = TextEditingController(text: widget.quest.notes);
    _priority = widget.quest.priority;
    _checklist = List.from(widget.quest.checklist);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _addChecklistItem() {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Add Checklist Item' : 'Добавить элемент'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEnglish ? 'Item text' : 'Текст элемента',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _checklist.add(QuestChecklistItem(
                    id: _generateId(),
                    text: controller.text.trim(),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      _checklist[index] = _checklist[index].copyWith(
        isCompleted: !_checklist[index].isCompleted,
      );
    });
  }

  void _editChecklistItem(int index) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;
    final item = _checklist[index];

    final controller = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Edit Checklist Item' : 'Редактировать элемент'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEnglish ? 'Item text' : 'Текст элемента',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _checklist[index] = item.copyWith(text: controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _deleteChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
  }

  void _save() {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    
    // Разрешаем сохранение даже с пустым названием
    final updatedQuest = widget.quest.copyWith(
      title: _titleController.text.trim().isEmpty 
          ? (isEnglish ? 'Untitled' : 'Без названия')
          : _titleController.text.trim(),
      notes: _notesController.text.trim(),
      priority: _priority,
      checklist: _checklist,
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, updatedQuest);
  }

  Color _getPriorityColor(QuestPriority priority) {
    switch (priority) {
      case QuestPriority.high:
        return Colors.red;
      case QuestPriority.medium:
        return Colors.orange;
      case QuestPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Edit Quest' : 'Редактировать квест'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: Text(l10n.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: isEnglish ? 'Title' : 'Название',
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Приоритет
            Text(
              isEnglish ? 'Priority' : 'Приоритет',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SegmentedButton<QuestPriority>(
              segments: [
                ButtonSegment(
                  value: QuestPriority.low,
                  label: Text(isEnglish ? 'Low' : 'Низкий'),
                  icon: Icon(Icons.arrow_downward, color: _getPriorityColor(QuestPriority.low)),
                ),
                ButtonSegment(
                  value: QuestPriority.medium,
                  label: Text(isEnglish ? 'Medium' : 'Средний'),
                  icon: Icon(Icons.remove, color: _getPriorityColor(QuestPriority.medium)),
                ),
                ButtonSegment(
                  value: QuestPriority.high,
                  label: Text(isEnglish ? 'High' : 'Высокий'),
                  icon: Icon(Icons.arrow_upward, color: _getPriorityColor(QuestPriority.high)),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (Set<QuestPriority> newSelection) {
                setState(() {
                  _priority = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Заметки
            Text(
              isEnglish ? 'Notes' : 'Заметки',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: isEnglish ? 'Enter notes...' : 'Введите заметки...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Чеклист
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEnglish ? 'Checklist' : 'Чеклист',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addChecklistItem,
                  tooltip: isEnglish ? 'Add Item' : 'Добавить элемент',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_checklist.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isEnglish ? 'No checklist items yet' : 'Пока нет элементов',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ..._checklist.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Checkbox(
                      value: item.isCompleted,
                      onChanged: (_) => _toggleChecklistItem(index),
                    ),
                    title: Text(
                      item.text,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isCompleted
                            ? Colors.grey
                            : null,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editChecklistItem(index);
                            break;
                          case 'delete':
                            _deleteChecklistItem(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 12),
                              Text(isEnglish ? 'Edit' : 'Редактировать'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 20, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                isEnglish ? 'Delete' : 'Удалить',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: Text(l10n.save),
      ),
    );
  }
}


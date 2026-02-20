// lib/pages/quest_folder_page.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/quest_folder.dart';
import '../models/quest.dart';
import '../l10n/app_localizations.dart';
import 'quest_edit_page.dart';

class QuestFolderPage extends StatefulWidget {
  final QuestFolder folder;
  final List<Quest> quests;
  final Function(List<Quest>) onQuestsChanged;

  const QuestFolderPage({
    super.key,
    required this.folder,
    required this.quests,
    required this.onQuestsChanged,
  });

  @override
  State<QuestFolderPage> createState() => _QuestFolderPageState();
}

class _QuestFolderPageState extends State<QuestFolderPage> {
  late List<Quest> _quests;

  @override
  void initState() {
    super.initState();
    _quests = List.from(widget.quests);
  }

  void _saveQuests() {
    widget.onQuestsChanged(_quests);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _addQuest() async {
    final newQuest = Quest(
      id: _generateId(),
      title: '',
      folderId: widget.folder.id,
      createdAt: DateTime.now(),
    );

    final result = await Navigator.push<Quest>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestEditPage(quest: newQuest),
      ),
    );

    if (result != null) {
      setState(() {
        _quests.add(result);
      });
      _saveQuests();
    }
  }

  void _editQuest(Quest quest) async {
    final index = _quests.indexWhere((q) => q.id == quest.id);
    if (index == -1) return;

    final result = await Navigator.push<Quest>(
      context,
      MaterialPageRoute(
        builder: (context) => QuestEditPage(quest: quest),
      ),
    );

    if (result != null) {
      setState(() {
        _quests[index] = result.copyWith(updatedAt: DateTime.now());
      });
      _saveQuests();
    }
  }

  void _deleteQuest(Quest quest) async {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Quest?' : 'Удалить квест?'),
        content: Text(
          isEnglish
              ? 'This action cannot be undone.'
              : 'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _quests.removeWhere((q) => q.id == quest.id);
      });
      _saveQuests();
    }
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

  String _getPriorityText(QuestPriority priority, bool isEnglish) {
    switch (priority) {
      case QuestPriority.high:
        return isEnglish ? 'High' : 'Высокий';
      case QuestPriority.medium:
        return isEnglish ? 'Medium' : 'Средний';
      case QuestPriority.low:
        return isEnglish ? 'Low' : 'Низкий';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
      ),
      body: _quests.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'No quests yet' : 'Пока нет квестов',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _quests.length,
              itemBuilder: (context, index) {
                final quest = _quests[index];
                final priorityColor = _getPriorityColor(quest.priority);
                final checklistProgress = quest.checklistProgress;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 4,
                      height: double.infinity,
                      color: priorityColor,
                    ),
                    title: Text(
                      quest.title.isEmpty ? (isEnglish ? 'Untitled' : 'Без названия') : quest.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: quest.checklist.isNotEmpty && checklistProgress == 1.0
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getPriorityText(quest.priority, isEnglish),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: priorityColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (quest.checklist.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${(checklistProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (quest.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            quest.notes,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editQuest(quest);
                            break;
                          case 'delete':
                            _deleteQuest(quest);
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
                    onTap: () => _editQuest(quest),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuest,
        child: const Icon(Icons.add),
        tooltip: isEnglish ? 'Add Quest' : 'Добавить квест',
      ),
    );
  }
}

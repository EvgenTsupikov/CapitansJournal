// lib/pages/quests_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/quest_folder.dart';
import '../models/quest.dart';
import '../l10n/app_localizations.dart';
import 'quest_folder_page.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  List<QuestFolder> _folders = [];
  List<Quest> _quests = [];

  static const String _foldersKey = 'quest_folders_json';
  static const String _questsKey = 'quests_json';

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadQuests();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_foldersKey);
    if (raw == null) {
      // Создаем дефолтные папки
      _folders = [
        QuestFolder(
          id: _generateId(),
          name: 'Бытовуха',
          createdAt: DateTime.now(),
        ),
        QuestFolder(
          id: _generateId(),
          name: 'Дойче квест',
          createdAt: DateTime.now(),
        ),
        QuestFolder(
          id: _generateId(),
          name: 'Сюжетка',
          createdAt: DateTime.now(),
        ),
        QuestFolder(
          id: _generateId(),
          name: 'Устойчивое развитие',
          createdAt: DateTime.now(),
        ),
      ];
      _saveFolders();
      return;
    }

    final arr = jsonDecode(raw) as List;
    _folders = arr.map((e) => QuestFolder.fromJson(e as Map<String, dynamic>)).toList();
    setState(() {});
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _foldersKey,
      jsonEncode(_folders.map((e) => e.toJson()).toList()),
    );
    setState(() {});
  }

  Future<void> _loadQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_questsKey);
    if (raw == null) {
      _quests = [];
      return;
    }

    final arr = jsonDecode(raw) as List;
    _quests = arr.map((e) => Quest.fromJson(e as Map<String, dynamic>)).toList();
    setState(() {});
  }

  Future<void> _saveQuests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _questsKey,
      jsonEncode(_quests.map((e) => e.toJson()).toList()),
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  void _addFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'New Folder' : 'Новая папка'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEnglish ? 'Folder name' : 'Название папки',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newFolder = QuestFolder(
        id: _generateId(),
        name: result,
        createdAt: DateTime.now(),
      );
      setState(() {
        _folders.add(newFolder);
      });
      _saveFolders();
    }
  }

  void _editFolder(QuestFolder folder) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final controller = TextEditingController(text: folder.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Edit Folder' : 'Редактировать папку'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isEnglish ? 'Folder name' : 'Название папки',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        final index = _folders.indexWhere((f) => f.id == folder.id);
        if (index != -1) {
          _folders[index] = folder.copyWith(
            name: result,
            updatedAt: DateTime.now(),
          );
        }
      });
      _saveFolders();
    }
  }

  void _deleteFolder(QuestFolder folder) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Folder?' : 'Удалить папку?'),
        content: Text(
          isEnglish
              ? 'All quests in this folder will also be deleted. This action cannot be undone.'
              : 'Все квесты в этой папке также будут удалены. Это действие нельзя отменить.',
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
        _folders.removeWhere((f) => f.id == folder.id);
        // Удаляем все квесты из этой папки
        _quests.removeWhere((q) => q.folderId == folder.id);
      });
      _saveFolders();
      _saveQuests();
    }
  }

  int _getQuestCount(String folderId) {
    return _quests.where((q) => q.folderId == folderId).length;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Quests' : 'Квесты'),
      ),
      body: _folders.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'No folders yet' : 'Пока нет папок',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          : ReorderableListView.builder(
              itemCount: _folders.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _folders.removeAt(oldIndex);
                  _folders.insert(newIndex, item);
                });
                _saveFolders();
              },
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final questCount = _getQuestCount(folder.id);

                return ListTile(
                  key: ValueKey(folder.id),
                  leading: const Icon(Icons.folder),
                  title: Text(folder.name),
                  subtitle: Text(
                    isEnglish
                        ? '$questCount ${questCount == 1 ? 'quest' : 'quests'}'
                        : '$questCount ${questCount == 1 ? 'квест' : questCount < 5 ? 'квеста' : 'квестов'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editFolder(folder);
                          break;
                        case 'delete':
                          _deleteFolder(folder);
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
                  onTap: () async {
                    // Загружаем актуальные данные перед переходом
                    await _loadQuests();
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestFolderPage(
                            folder: folder,
                            quests: _quests.where((q) => q.folderId == folder.id).toList(),
                            onQuestsChanged: (updatedQuests) {
                              setState(() {
                                // Обновляем квесты
                                _quests.removeWhere((q) => q.folderId == folder.id);
                                _quests.addAll(updatedQuests);
                              });
                              _saveQuests();
                            },
                          ),
                        ),
                      ).then((_) {
                        // Обновляем список после возврата
                        _loadQuests();
                      });
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        child: const Icon(Icons.add),
        tooltip: isEnglish ? 'Add Folder' : 'Добавить папку',
      ),
    );
  }
}


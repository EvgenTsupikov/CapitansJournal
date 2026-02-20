// lib/pages/notes_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';
import '../models/action_log.dart';
import '../models/deleted_note.dart';
import '../models/template.dart';
import '../models/command.dart';
import '../widgets/note_input.dart';
import '../l10n/app_localizations.dart';
import 'settings_page.dart';
import 'logs_page.dart';
import 'trash_page.dart';
import 'calendar_view_page.dart';
import 'commands_page.dart';
import 'quests_page.dart';

/// TextInputFormatter для автоматической капитализации первой буквы в новой строке
class CapitalizeNewLineFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Если текст не изменился, возвращаем как есть
    if (oldValue.text == newValue.text) {
      return newValue;
    }

    // Получаем позицию курсора
    final cursorPosition = newValue.selection.baseOffset;
    
    // Если текст стал длиннее (добавлен символ) и курсор не в начале
    if (newValue.text.length > oldValue.text.length && cursorPosition > 0) {
      // Получаем только что введенный символ (он находится на позиции cursorPosition - 1)
      final insertedCharIndex = cursorPosition - 1;
      
      if (insertedCharIndex < newValue.text.length) {
        final insertedChar = newValue.text[insertedCharIndex];
        
        // Проверяем, является ли введенный символ первой буквой в строке
        // (т.е. перед ним только пробелы и символ новой строки)
        bool isFirstCharInLine = true;
        for (int i = insertedCharIndex - 1; i >= 0; i--) {
          final char = newValue.text[i];
          if (char == '\n') {
            break; // Нашли начало строки
          } else if (char != ' ' && char != '\t') {
            isFirstCharInLine = false;
            break;
          }
        }
        
        // Если это первая буква в строке и она в нижнем регистре, делаем её заглавной
        if (isFirstCharInLine && _isLetter(insertedChar) && !_isUpperCase(insertedChar)) {
          final newText = newValue.text.substring(0, insertedCharIndex) +
              insertedChar.toUpperCase() +
              newValue.text.substring(insertedCharIndex + 1);
          
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition),
          );
        }
      }
    } else if (cursorPosition == 1 && newValue.text.isNotEmpty) {
      // Если курсор на позиции 1 (только что введен первый символ)
      final firstChar = newValue.text[0];
      if (_isLetter(firstChar) && !_isUpperCase(firstChar)) {
        final newText = firstChar.toUpperCase() + newValue.text.substring(1);
        return TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: 1),
        );
      }
    }

    return newValue;
  }

  bool _isLetter(String char) {
    return char.toLowerCase() != char.toUpperCase();
  }

  bool _isUpperCase(String char) {
    return char == char.toUpperCase() && char != char.toLowerCase();
  }
}

const double _headerHeight = 56;

class NotesPage extends StatefulWidget {
  final void Function(bool isDark)? onThemeChanged;
  final void Function(Locale locale)? onLanguageChanged;
  final Locale? currentLocale;

  const NotesPage({
    super.key,
    this.onThemeChanged,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ScrollController _calendarScroll = ScrollController();
  TabController? _tabController;

  final List<Note> _notes = [];
  final List<DeletedNote> _deletedNotes = [];
  final List<ActionLog> _actionLogs = [];
  List<Template> _templates = [];
  List<Command> _commands = [];
  final Map<String, bool> _expandedMap = {};

  static const String _prefsKey = 'notes_json';
  static const String _tabOrderKey = 'tab_order';
  static const String _tabVisibilityKey = 'tab_visibility';
  static const String _defaultTabKey = 'default_tab';

  List<String> _tabOrder = ['notes', 'calendar', 'quests'];
  Map<String, bool> _tabVisibility = {
    'notes': true,
    'calendar': true,
    'quests': true,
  };
  String _defaultTab = 'notes';
  static const String _deletedNotesKey = 'deleted_notes_json';
  static const String _actionLogsKey = 'action_logs_json';
  static const String _draftTextKey = 'draft_text';
  static const String _templatesKey = 'templates_json';
  static const String _commandsKey = 'commands_json';
  static const String _notesScrollPositionKey = 'notes_scroll_position';
  static const String _calendarScrollPositionKey = 'calendar_scroll_position';
  static const String _editingNoteStateKey = 'editing_note_state';
  static const String _animationsEnabledKey = 'animations_enabled';
  
  bool _animationsEnabled = true;

  // ─────────────────────────────────────────────
  Future<void> _initializeTabs() async {
    await _loadTabSettings();
    final visibleTabs = _getVisibleTabs();
    final visibleTabsCount = visibleTabs.length;
    if (visibleTabsCount > 0) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(length: visibleTabsCount, vsync: this);
      
      // Устанавливаем выбранную вкладку по умолчанию
      final defaultTabIndex = visibleTabs.indexOf(_defaultTab);
      if (mounted) {
        // Используем addPostFrameCallback для установки вкладки после построения
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabController != null && mounted) {
            if (defaultTabIndex >= 0) {
              if (_animationsEnabled) {
                _tabController!.animateTo(defaultTabIndex);
              } else {
                _tabController!.index = defaultTabIndex;
              }
            } else if (oldIndex < visibleTabsCount) {
              if (_animationsEnabled) {
                _tabController!.animateTo(oldIndex);
              } else {
                _tabController!.index = oldIndex;
              }
            }
            // Вызываем setState после установки индекса
            if (mounted) {
              setState(() {});
            }
          }
        });
      }
    }
  }

  Future<void> _loadAnimationsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _animationsEnabled = prefs.getBool(_animationsEnabledKey) ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAnimationsSetting();
    _initializeTabs();
    _loadNotes();
    _loadDeletedNotes();
    _loadActionLogs();
    _loadTemplates();
    _loadCommands();
    _loadDraftText();
    _cleanupOldDeletedNotes();
    _scroll.addListener(_saveNotesScrollPosition);
    _calendarScroll.addListener(_saveCalendarScrollPosition);
    _controller.addListener(_saveDraftText);
    _loadScrollPositions();
    // Восстанавливаем состояние редактирования после загрузки заметок
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreEditingNoteState();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_saveDraftText);
    _scroll.removeListener(_saveNotesScrollPosition);
    _calendarScroll.removeListener(_saveCalendarScrollPosition);
    _controller.dispose();
    _scroll.dispose();
    _calendarScroll.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDate(String key) {
    final p = key.split('-');
    return '${p[2]}.${p[1]}.${p[0]}';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Map<String, List<Note>> _groupByDate() {
    final map = <String, List<Note>>{};
    for (final n in _notes) {
      final key = _dateKey(n.createdAt);
      map.putIfAbsent(key, () => []).add(n);
    }
    for (final v in map.values) {
      v.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return map;
  }


  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  void _addNote({DateTime? customDateTime}) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final createdAt = customDateTime ?? DateTime.now();
    final newNote = Note(text: text, createdAt: createdAt);
    setState(() {
      _notes.add(newNote);
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    _controller.clear();
    _clearDraftText();
    _saveNotes();
    _logAction('create', newNote.text);
  }

  Future<void> _copyDay(String key) async {
    final items = _groupByDate()[key];
    if (items == null) return;

    final buf = StringBuffer()..writeln(_formatDate(key));
    for (final n in items.reversed) {
      buf.writeln('${_formatTime(n.createdAt)}: ${n.text}');
    }

    await Clipboard.setData(ClipboardData(text: buf.toString()));
  }

  void _editNote(Note note, {String? savedText}) {
    final l10n = AppLocalizations.of(context)!;
    final editController = TextEditingController(text: savedText ?? note.text);
    
    // Сохраняем состояние редактирования
    _saveEditingNoteState(note.createdAt.toIso8601String(), editController.text);
    
    // Добавляем слушатель для сохранения текста при изменении
    editController.addListener(() {
      _saveEditingNoteState(note.createdAt.toIso8601String(), editController.text);
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editNote),
        content: TextField(
          controller: editController,
          maxLines: null,
          autofocus: true,
          inputFormatters: [CapitalizeNewLineFormatter()],
          decoration: InputDecoration(
            hintText: l10n.enterNoteText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearEditingNoteState();
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              _clearEditingNoteState();
              if (newText.isNotEmpty && newText != note.text) {
                final oldText = note.text;
                setState(() {
                  note.text = newText;
                  _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                });
                _saveNotes();
                _logAction('edit', newText, metadata: {'oldText': oldText});
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _changeNoteDate(Note note) async {
    final l10n = AppLocalizations.of(context)!;
    final initialDate = note.createdAt;
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.selectDate,
    );
    
    if (pickedDate == null) return;
    
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      initialDate.hour,
      initialDate.minute,
      initialDate.second,
      initialDate.millisecond,
    );
    
    setState(() {
      note.createdAt = newDateTime;
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    _saveNotes();
    _logAction('change_date', note.text, metadata: {
      'newDate': newDateTime.toIso8601String(),
    });
  }

  Future<void> _changeNoteTime(Note note) async {
    final l10n = AppLocalizations.of(context)!;
    final initialDate = note.createdAt;
    
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: l10n.selectTime,
    );
    
    if (pickedTime == null) return;
    
    final newDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      pickedTime.hour,
      pickedTime.minute,
      initialDate.second,
      initialDate.millisecond,
    );
    
    setState(() {
      note.createdAt = newDateTime;
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    _saveNotes();
    _logAction('change_time', note.text, metadata: {
      'newTime': newDateTime.toIso8601String(),
    });
  }

  void _deleteNote(Note note) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.deleteNote)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteConfirmation),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note.text,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.cannotUndo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _moveToTrash(note);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.noteDeleted),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;

    final arr = jsonDecode(raw) as List;
    _notes
      ..clear()
      ..addAll(arr.map((e) => Note.fromJson(e)));

    setState(() {});
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_notes.map((e) => e.toJson()).toList()),
    );
  }

  // ─────────────────────────────────────────────
  // Draft Text (сохранение текста в поле ввода)
  // ─────────────────────────────────────────────

  Future<void> _loadDraftText() async {
    final prefs = await SharedPreferences.getInstance();
    final draftText = prefs.getString(_draftTextKey);
    if (draftText != null && draftText.isNotEmpty) {
      _controller.text = draftText;
    }
  }

  void _saveDraftText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftTextKey, _controller.text);
  }

  Future<void> _clearDraftText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftTextKey);
  }

  // ─────────────────────────────────────────────
  // Editing Note State (сохранение состояния редактирования)
  // ─────────────────────────────────────────────

  Future<void> _saveEditingNoteState(String noteCreatedAt, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _editingNoteStateKey,
      jsonEncode({
        'noteCreatedAt': noteCreatedAt,
        'text': text,
      }),
    );
  }

  Future<void> _clearEditingNoteState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_editingNoteStateKey);
  }

  Future<void> _restoreEditingNoteState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateJson = prefs.getString(_editingNoteStateKey);
    if (stateJson == null) return;

    try {
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      final noteCreatedAtStr = state['noteCreatedAt'] as String;
      final savedText = state['text'] as String?;

      if (savedText == null || savedText.isEmpty) {
        _clearEditingNoteState();
        return;
      }

      // Ищем заметку по дате создания
      final note = _notes.firstWhere(
        (n) => n.createdAt.toIso8601String() == noteCreatedAtStr,
        orElse: () => Note(text: '', createdAt: DateTime.now()),
      );

      // Если заметка не найдена, очищаем состояние
      if (note.text.isEmpty && note.createdAt == DateTime.now()) {
        _clearEditingNoteState();
        return;
      }

      // Открываем диалог редактирования с сохраненным текстом
      if (mounted) {
        _editNote(note, savedText: savedText);
      }
    } catch (e) {
      // В случае ошибки очищаем состояние
      _clearEditingNoteState();
    }
  }

  // ─────────────────────────────────────────────
  // Scroll Position Saving
  // ─────────────────────────────────────────────

  Future<void> _loadScrollPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final notesPosition = prefs.getDouble(_notesScrollPositionKey);
    final calendarPosition = prefs.getDouble(_calendarScrollPositionKey);
    
    if (notesPosition != null && _scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scroll.jumpTo(notesPosition);
      });
    }
    
    if (calendarPosition != null && _calendarScroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calendarScroll.jumpTo(calendarPosition);
      });
    }
  }

  void _saveNotesScrollPosition() async {
    if (_scroll.hasClients) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_notesScrollPositionKey, _scroll.offset);
    }
  }

  void _saveCalendarScrollPosition() async {
    if (_calendarScroll.hasClients) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_calendarScrollPositionKey, _calendarScroll.offset);
    }
  }

  // ─────────────────────────────────────────────
  // Logging
  // ─────────────────────────────────────────────

  void _logAction(String action, String noteText, {Map<String, dynamic>? metadata}) {
    final log = ActionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      noteText: noteText,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    setState(() {
      _actionLogs.insert(0, log);
      if (_actionLogs.length > 1000) {
        _actionLogs.removeRange(1000, _actionLogs.length);
      }
    });
    _saveActionLogs();
  }

  Future<void> _loadActionLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_actionLogsKey);
    if (raw == null) return;

    final arr = jsonDecode(raw) as List;
    _actionLogs
      ..clear()
      ..addAll(arr.map((e) => ActionLog.fromJson(e)));
  }

  Future<void> _saveActionLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _actionLogsKey,
      jsonEncode(_actionLogs.map((e) => e.toJson()).toList()),
    );
  }

  // ─────────────────────────────────────────────
  // Trash (Deleted Notes)
  // ─────────────────────────────────────────────

  Future<void> _loadDeletedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_deletedNotesKey);
    if (raw == null) return;

    final arr = jsonDecode(raw) as List;
    _deletedNotes
      ..clear()
      ..addAll(arr.map((e) => DeletedNote.fromJson(e)));
  }

  Future<void> _saveDeletedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _deletedNotesKey,
      jsonEncode(_deletedNotes.map((e) => e.toJson()).toList()),
    );
  }

  void _cleanupOldDeletedNotes() {
    final now = DateTime.now();
    final toRemove = <DeletedNote>[];
    
    for (final deletedNote in _deletedNotes) {
      if (now.difference(deletedNote.deletedAt).inDays >= 30) {
        toRemove.add(deletedNote);
      }
    }

    if (toRemove.isNotEmpty) {
      setState(() {
        _deletedNotes.removeWhere((note) => toRemove.contains(note));
      });
      _saveDeletedNotes();
    }
  }

  void _moveToTrash(Note note) {
    setState(() {
      _notes.remove(note);
      _deletedNotes.add(DeletedNote(
        note: note,
        deletedAt: DateTime.now(),
      ));
    });
    _saveNotes();
    _saveDeletedNotes();
    _logAction('delete', note.text);
  }

  void _restoreNote(DeletedNote deletedNote) {
    setState(() {
      _deletedNotes.remove(deletedNote);
      _notes.add(deletedNote.note);
      _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
    _saveNotes();
    _saveDeletedNotes();
    _logAction('restore', deletedNote.note.text);
  }

  // ─────────────────────────────────────────────
  // Templates
  // ─────────────────────────────────────────────

  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    if (raw == null) {
      // Создаем дефолтные шаблоны
      _templates = [
        Template(
          id: '1',
          name: 'Утро',
          location: '',
          state: '',
          practices: '',
        ),
        Template(
          id: '2',
          name: 'Вечер',
          location: '',
          state: '',
          practices: '',
        ),
      ];
      _saveTemplates();
      return;
    }

    final arr = jsonDecode(raw) as List;
    _templates = arr.map((e) => Template.fromJson(e)).toList();
    setState(() {});
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _templatesKey,
      jsonEncode(_templates.map((e) => e.toJson()).toList()),
    );
  }


  // ─────────────────────────────────────────────
  // Commands
  // ─────────────────────────────────────────────

  Future<void> _loadCommands() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_commandsKey);
    if (raw == null) {
      // Создаем дефолтную команду location с иерархической структурой
      _commands = [
        Command(
          name: 'location',
          values: [
            LocationValue(
              name: 'Germany',
              children: [
                LocationValue(
                  name: 'Munich',
                  children: [
                    LocationValue(name: 'City Center'),
                    LocationValue(name: 'Airport'),
                  ],
                ),
              ],
            ),
            LocationValue(
              name: 'Ukraine',
              children: [
                LocationValue(
                  name: 'Kiev',
                  children: [
                    LocationValue(name: 'City Center'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];
      _saveCommands();
      return;
    }

    final arr = jsonDecode(raw) as List;
    _commands = arr.map((e) => Command.fromJson(e)).toList();
    setState(() {});
  }

  Future<void> _saveCommands() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _commandsKey,
      jsonEncode(_commands.map((e) => e.toJson()).toList()),
    );
  }

  void _onCommandsChanged(List<Command> commands) {
    setState(() {
      _commands = commands;
    });
    _saveCommands();
  }

  // ─────────────────────────────────────────────
  // Tab Settings
  // ─────────────────────────────────────────────

  Future<void> _loadTabSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString(_tabOrderKey);
    final visibilityJson = prefs.getString(_tabVisibilityKey);
    final defaultTab = prefs.getString(_defaultTabKey);
    
    if (orderJson != null) {
      final order = jsonDecode(orderJson) as List;
      setState(() {
        _tabOrder = order.cast<String>();
      });
    }
    
    if (visibilityJson != null) {
      final visibility = jsonDecode(visibilityJson) as Map;
      setState(() {
        _tabVisibility = visibility.map((key, value) => MapEntry(key as String, value as bool));
      });
    }
    
    if (defaultTab != null) {
      setState(() {
        _defaultTab = defaultTab;
      });
    }
  }

  List<String> _getVisibleTabs() {
    return _tabOrder.where((tabId) => _tabVisibility[tabId] ?? true).toList();
  }

  String _getTabName(String tabId, bool isEnglish) {
    switch (tabId) {
      case 'notes':
        return isEnglish ? 'Notes' : 'Заметки';
      case 'calendar':
        return isEnglish ? 'Calendar' : 'Календарь';
      case 'quests':
        return isEnglish ? 'Quests' : 'Квесты';
      default:
        return tabId;
    }
  }

  Widget _getTabWidget(String tabId, Map<String, List<Note>> grouped, List<String> keys) {
    switch (tabId) {
      case 'notes':
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: NoteInput(
                controller: _controller,
                onSend: () => _addNote(),
                onSendWithDateTime: (dateTime) {
                  if (dateTime != null) {
                    _addNote(customDateTime: dateTime);
                  }
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final notes = grouped[key]!;
                  final today = DateTime.now();
                  final todayKey = _dateKey(today);
                  final expanded = _expandedMap[key] ?? (key == todayKey);
                  
                    return _DaySection(
                      dayKey: key,
                      notes: notes,
                      isExpanded: expanded,
                      formatDate: _formatDate(key),
                      formatTime: _formatTime,
                      animationsEnabled: _animationsEnabled,
                      onToggle: () {
                        setState(() {
                          _expandedMap[key] = !expanded;
                        });
                      },
                      onCopy: () => _copyDay(key),
                      onEditNote: _editNote,
                      onDeleteNote: _deleteNote,
                      onChangeNoteDate: _changeNoteDate,
                      onChangeNoteTime: _changeNoteTime,
                    );
                },
              ),
            ),
          ],
        );
      case 'calendar':
        return CalendarViewPage(
          notes: _notes,
          onEditNote: (note) => _editNote(note),
          onDeleteNote: (note) => _deleteNote(note),
          scrollController: _calendarScroll,
          commands: _commands,
        );
      case 'quests':
        return const QuestsPage();
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = _groupByDate();
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    final visibleTabs = _getVisibleTabs();
    
    // Если TabController еще не инициализирован, показываем загрузку
    if (_tabController == null || _tabController!.length != visibleTabs.length) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        bottom: visibleTabs.isEmpty
            ? null
            : TabBar(
                controller: _tabController!,
                tabs: visibleTabs.map((tabId) => Tab(text: _getTabName(tabId, isEnglish))).toList(),
              ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'commands':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommandsPage(
                        commands: _commands,
                        onCommandsChanged: _onCommandsChanged,
                      ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                  break;
                case 'history':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogsPage(actionLogs: _actionLogs),
                    ),
                  );
                  break;
                case 'trash':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrashPage(
                        deletedNotes: _deletedNotes,
                        onRestore: _restoreNote,
                        onPermanentDelete: (deletedNote) {
                          setState(() {
                            _deletedNotes.remove(deletedNote);
                          });
                          _saveDeletedNotes();
                        },
                      ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'commands',
                child: Row(
                  children: [
                    const Text('#', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text(isEnglish ? 'Commands' : 'Команды'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 12),
                    Text(isEnglish ? 'History' : 'История'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'trash',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 20),
                    const SizedBox(width: 12),
                    Text(isEnglish ? 'Trash' : 'Корзина'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    isDarkTheme: Theme.of(context).brightness == Brightness.dark,
                    onThemeChanged: widget.onThemeChanged ?? (bool _) {},
                    onLanguageChanged: widget.onLanguageChanged,
                    currentLocale: widget.currentLocale,
                  ),
                ),
              ).then((_) async {
                // Обновляем вкладки и настройки анимаций после возврата из настроек
                await _loadAnimationsSetting();
                // Проверяем, нужно ли пересоздавать TabController
                await _loadTabSettings();
                final visibleTabs = _getVisibleTabs();
                final visibleTabsCount = visibleTabs.length;
                
                // Пересоздаем TabController только если количество вкладок изменилось
                if (_tabController == null || _tabController!.length != visibleTabsCount) {
                  await _initializeTabs();
                } else {
                  // Просто обновляем состояние, чтобы виджеты перестроились
                  if (mounted) {
                    setState(() {});
                  }
                }
              });
            },
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: visibleTabs.isEmpty
          ? Center(
              child: Text(
                isEnglish ? 'No tabs available' : 'Нет доступных вкладок',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : TabBarView(
              controller: _tabController!,
              children: visibleTabs.map((tabId) => _getTabWidget(tabId, grouped, keys)).toList(),
            ),
    );
  }
}

/// Виджет секции дня с заголовком и заметками
class _DaySection extends StatelessWidget {
  final String dayKey;
  final List<Note> notes;
  final bool isExpanded;
  final String formatDate;
  final String Function(DateTime) formatTime;
  final bool animationsEnabled;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final Function(Note) onEditNote;
  final Function(Note) onDeleteNote;
  final Function(Note) onChangeNoteDate;
  final Function(Note) onChangeNoteTime;

  const _DaySection({
    required this.dayKey,
    required this.notes,
    required this.isExpanded,
    required this.formatDate,
    required this.formatTime,
    required this.animationsEnabled,
    required this.onToggle,
    required this.onCopy,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onChangeNoteDate,
    required this.onChangeNoteTime,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Заголовок дня
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: _headerHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Text(
                    formatDate,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: onCopy,
                tooltip: l10n.copy,
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
        ),
        // Заметки дня с анимацией или без
        animationsEnabled
            ? AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: notes.map((note) {
                    return GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: Text(l10n.editText),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onEditNote(note);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.calendar_today),
                                  title: Text(l10n.changeDate),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onChangeNoteDate(note);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: Text(l10n.changeTime),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onChangeNoteTime(note);
                                  },
                                ),
                                const Divider(),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    onDeleteNote(note);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatTime(note.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                note.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                      )
                    : const SizedBox.shrink(),
              )
            : (isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: notes.map((note) {
                      return GestureDetector(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(l10n.editText),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onEditNote(note);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.calendar_today),
                                    title: Text(l10n.changeDate),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onChangeNoteDate(note);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.access_time),
                                    title: Text(l10n.changeTime),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onChangeNoteTime(note);
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onDeleteNote(note);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatTime(note.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink()),
      ],
    );
  }
}

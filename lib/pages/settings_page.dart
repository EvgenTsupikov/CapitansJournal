// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note.dart';
import '../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkTheme;
  final void Function(bool isDark) onThemeChanged;
  final void Function(Locale locale)? onLanguageChanged;
  final Locale? currentLocale;

  const SettingsPage({
    super.key,
    required this.isDarkTheme,
    required this.onThemeChanged,
    this.onLanguageChanged,
    this.currentLocale,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDarkTheme;
  int _totalNotes = 0;
  int _totalDays = 0;
  bool _animationsEnabled = true;
  static const String _animationsEnabledKey = 'animations_enabled';

  @override
  void initState() {
    super.initState();
    _isDarkTheme = widget.isDarkTheme;
    _loadStatistics();
    _loadAnimationsSetting();
  }

  Future<void> _loadAnimationsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _animationsEnabled = prefs.getBool(_animationsEnabledKey) ?? true;
    });
  }

  Future<void> _saveAnimationsSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsEnabledKey, value);
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes_json');
    if (raw != null) {
      final arr = jsonDecode(raw) as List;
      final notes = arr.map((e) => Note.fromJson(e)).toList();
      
      final dates = <String>{};
      for (final note in notes) {
        final dateKey = '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}';
        dates.add(dateKey);
      }
      
      setState(() {
        _totalNotes = notes.length;
        _totalDays = dates.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = widget.currentLocale?.languageCode ?? 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // ─────────────────────────────────────────────
          // Внешний вид
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.appearance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.darkTheme),
            subtitle: Text(l10n.darkThemeSubtitle),
            value: _isDarkTheme,
            onChanged: (value) {
              setState(() {
                _isDarkTheme = value;
              });
              widget.onThemeChanged(value);
            },
            secondary: Icon(
              _isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(l10n.languageSubtitle),
            trailing: DropdownButton<String>(
              value: currentLang,
              items: [
                DropdownMenuItem(value: 'ru', child: Text(l10n.russian)),
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'uk', child: Text(l10n.ukrainian)),
                DropdownMenuItem(value: 'de', child: Text(l10n.german)),
              ],
              onChanged: (String? newLang) {
                if (newLang != null && widget.onLanguageChanged != null) {
                  widget.onLanguageChanged!(Locale(newLang));
                  setState(() {
                    _loadStatistics();
                  });
                }
              },
            ),
          ),

          const Divider(),

          // ─────────────────────────────────────────────
          // UI
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.ui,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tab),
            title: Text(l10n.tabOrder),
            subtitle: Text(l10n.tabOrderSubtitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _TabOrderSettingsPage(),
                ),
              );
            },
          ),

          const Divider(),

          // ─────────────────────────────────────────────
          // Анимации
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.animations,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.enableAnimations),
            subtitle: Text(l10n.animationsSubtitle),
            value: _animationsEnabled,
            onChanged: (value) {
              setState(() {
                _animationsEnabled = value;
              });
              _saveAnimationsSetting(value);
            },
            secondary: Icon(
              _animationsEnabled ? Icons.animation : Icons.animation_outlined,
            ),
          ),

          const Divider(),

          // ─────────────────────────────────────────────
          // Статистика
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.statistics,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: Text(l10n.totalNotes),
            trailing: Text(
              '$_totalNotes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.daysWithNotes),
            trailing: Text(
              '$_totalDays',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(),

          // ─────────────────────────────────────────────
          // Данные
          // ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.data,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            subtitle: Text(l10n.version),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.aboutDialogTitle),
                  content: Text(l10n.aboutDialogContent),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabOrderSettingsPage extends StatefulWidget {
  @override
  State<_TabOrderSettingsPage> createState() => _TabOrderSettingsPageState();
}

class _TabOrderSettingsPageState extends State<_TabOrderSettingsPage> {
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
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

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tabOrderKey, jsonEncode(_tabOrder));
    await prefs.setString(_tabVisibilityKey, jsonEncode(_tabVisibility));
    await prefs.setString(_defaultTabKey, _defaultTab);
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

  List<String> _getVisibleTabs() {
    return _tabOrder.where((tabId) => _tabVisibility[tabId] ?? true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final visibleTabs = _getVisibleTabs();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabOrder),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check),
            label: Text(isEnglish ? 'Save Changes' : 'Сохранить изменения'),
            onPressed: () {
              _saveSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Превью вкладок
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Current Tab Display' : 'Текущее отображение вкладок',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (visibleTabs.isEmpty)
                  Text(
                    isEnglish ? 'No visible tabs' : 'Нет видимых вкладок',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleTabs.map((tabId) {
                      final isDefault = tabId == _defaultTab;
                      return Chip(
                        label: Text(_getTabName(tabId, isEnglish)),
                        avatar: isDefault
                            ? const Icon(Icons.star, size: 16)
                            : null,
                        backgroundColor: isDefault
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                // Выбор вкладки по умолчанию
                DropdownButtonFormField<String>(
                  value: _defaultTab,
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Default Tab' : 'Вкладка по умолчанию',
                    border: const OutlineInputBorder(),
                  ),
                  items: visibleTabs.map((tabId) {
                    return DropdownMenuItem(
                      value: tabId,
                      child: Text(_getTabName(tabId, isEnglish)),
                    );
                  }).toList(),
                  onChanged: visibleTabs.isEmpty
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _defaultTab = value;
                            });
                            _saveSettings();
                          }
                        },
                ),
              ],
            ),
          ),
          // Список вкладок для настройки
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _tabOrder.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _tabOrder.removeAt(oldIndex);
                  _tabOrder.insert(newIndex, item);
                });
                _saveSettings();
                // Обновляем превью после изменения порядка
                setState(() {});
              },
        itemBuilder: (context, index) {
          final tabId = _tabOrder[index];
          final isVisible = _tabVisibility[tabId] ?? true;

          return ListTile(
            key: ValueKey(tabId),
            title: Text(_getTabName(tabId, isEnglish)),
            subtitle: Text(
              isVisible
                  ? (isEnglish ? 'Visible' : 'Видима')
                  : (isEnglish ? 'Hidden' : 'Скрыта'),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isVisible,
                  onChanged: (value) {
                    setState(() {
                      _tabVisibility[tabId] = value;
                      // Если скрываем вкладку, которая была по умолчанию, выбираем первую видимую
                      if (!value && _defaultTab == tabId) {
                        final newVisibleTabs = _getVisibleTabs();
                        if (newVisibleTabs.isNotEmpty) {
                          _defaultTab = newVisibleTabs.first;
                        }
                      }
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(width: 5),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}


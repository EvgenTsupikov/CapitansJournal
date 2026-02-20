// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ru': {
      // Notes Page
      'app_title': 'Captain\'s Journal',
      'hint_text': 'Введите заметку...',
      'edit_note': 'Редактировать заметку',
      'enter_note_text': 'Введите текст заметки...',
      'cancel': 'Отмена',
      'save': 'Сохранить',
      'change_date': 'Изменить дату',
      'change_time': 'Изменить время',
      'select_date': 'Выберите дату',
      'select_time': 'Выберите время',
      'delete_note': 'Удалить заметку?',
      'delete_confirmation': 'Вы уверены, что хотите удалить эту заметку?',
      'cannot_undo': 'Это действие нельзя отменить.',
      'delete': 'Удалить',
      'note_deleted': 'Заметка удалена',
      'edit_text': 'Редактировать текст',
      'copy': 'Копировать',
      
      // Settings Page
      'settings': 'Настройки',
      'appearance': 'Внешний вид',
      'dark_theme': 'Темная тема',
      'dark_theme_subtitle': 'Переключить между светлой и темной темой',
      'statistics': 'Статистика',
      'total_notes': 'Всего заметок',
      'days_with_notes': 'Дней с заметками',
      'data': 'Данные',
      'about_app': 'О приложении',
      'version': 'Версия 1.0.0',
      'about_dialog_title': 'О приложении',
      'about_dialog_content': 'Captain\'s Journal\n\nПростое приложение для ведения дневника и заметок.\n\nВерсия: 1.0.0',
      'close': 'Закрыть',
      'language': 'Язык',
      'language_subtitle': 'Выберите язык интерфейса',
      'russian': 'Русский',
      'english': 'English',
      'ui': 'Интерфейс',
      'ui_subtitle': 'Настройка отображения элементов интерфейса',
      'tab_order': 'Порядок вкладок',
      'tab_order_subtitle': 'Изменить порядок или скрыть вкладки',
      'hide_tab': 'Скрыть вкладку',
      'show_tab': 'Показать вкладку',
      'animations': 'Анимации',
      'animations_subtitle': 'Включить или выключить анимации в приложении',
      'enable_animations': 'Включить анимации',
    },
    'en': {
      // Notes Page
      'app_title': 'Captain\'s Journal',
      'hint_text': 'Enter note...',
      'edit_note': 'Edit Note',
      'enter_note_text': 'Enter note text...',
      'cancel': 'Cancel',
      'save': 'Save',
      'change_date': 'Change Date',
      'change_time': 'Change Time',
      'select_date': 'Select Date',
      'select_time': 'Select Time',
      'delete_note': 'Delete Note?',
      'delete_confirmation': 'Are you sure you want to delete this note?',
      'cannot_undo': 'This action cannot be undone.',
      'delete': 'Delete',
      'note_deleted': 'Note deleted',
      'edit_text': 'Edit Text',
      'copy': 'Copy',
      
      // Settings Page
      'settings': 'Settings',
      'appearance': 'Appearance',
      'dark_theme': 'Dark Theme',
      'dark_theme_subtitle': 'Switch between light and dark theme',
      'statistics': 'Statistics',
      'total_notes': 'Total Notes',
      'days_with_notes': 'Days with Notes',
      'data': 'Data',
      'about_app': 'About',
      'version': 'Version 1.0.0',
      'about_dialog_title': 'About',
      'about_dialog_content': 'Captain\'s Journal\n\nSimple app for keeping a diary and notes.\n\nVersion: 1.0.0',
      'close': 'Close',
      'language': 'Language',
      'language_subtitle': 'Select interface language',
      'russian': 'Русский',
      'english': 'English',
      'ukrainian': 'Українська',
      'german': 'Deutsch',
      'ui': 'UI',
      'ui_subtitle': 'Interface display settings',
      'tab_order': 'Tab Order',
      'tab_order_subtitle': 'Change order or hide tabs',
      'hide_tab': 'Hide Tab',
      'show_tab': 'Show Tab',
      'animations': 'Animations',
      'animations_subtitle': 'Enable or disable animations in the app',
      'enable_animations': 'Enable Animations',
    },
    'uk': {
      // Notes Page
      'app_title': 'Captain\'s Journal',
      'hint_text': 'Введіть нотатку...',
      'edit_note': 'Редагувати нотатку',
      'enter_note_text': 'Введіть текст нотатки...',
      'cancel': 'Скасувати',
      'save': 'Зберегти',
      'change_date': 'Змінити дату',
      'change_time': 'Змінити час',
      'select_date': 'Виберіть дату',
      'select_time': 'Виберіть час',
      'delete_note': 'Видалити нотатку?',
      'delete_confirmation': 'Ви впевнені, що хочете видалити цю нотатку?',
      'cannot_undo': 'Цю дію не можна скасувати.',
      'delete': 'Видалити',
      'note_deleted': 'Нотатку видалено',
      'edit_text': 'Редагувати текст',
      'copy': 'Копіювати',
      
      // Settings Page
      'settings': 'Налаштування',
      'appearance': 'Зовнішній вигляд',
      'dark_theme': 'Темна тема',
      'dark_theme_subtitle': 'Перемкнути між світлою та темною темою',
      'statistics': 'Статистика',
      'total_notes': 'Всього нотаток',
      'days_with_notes': 'Днів з нотатками',
      'data': 'Дані',
      'about_app': 'Про додаток',
      'version': 'Версія 1.0.0',
      'about_dialog_title': 'Про додаток',
      'about_dialog_content': 'Captain\'s Journal\n\nПростий додаток для ведення щоденника та нотаток.\n\nВерсія: 1.0.0',
      'close': 'Закрити',
      'language': 'Мова',
      'language_subtitle': 'Виберіть мову інтерфейсу',
      'russian': 'Русский',
      'english': 'English',
      'ukrainian': 'Українська',
      'german': 'Deutsch',
      'ui': 'Інтерфейс',
      'ui_subtitle': 'Налаштування відображення елементів інтерфейсу',
      'tab_order': 'Порядок вкладок',
      'tab_order_subtitle': 'Змінити порядок або приховати вкладки',
      'hide_tab': 'Приховати вкладку',
      'show_tab': 'Показати вкладку',
      'animations': 'Анімації',
      'animations_subtitle': 'Увімкнути або вимкнути анімації в додатку',
      'enable_animations': 'Увімкнути анімації',
    },
    'de': {
      // Notes Page
      'app_title': 'Captain\'s Journal',
      'hint_text': 'Notiz eingeben...',
      'edit_note': 'Notiz bearbeiten',
      'enter_note_text': 'Notiztext eingeben...',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'change_date': 'Datum ändern',
      'change_time': 'Uhrzeit ändern',
      'select_date': 'Datum auswählen',
      'select_time': 'Uhrzeit auswählen',
      'delete_note': 'Notiz löschen?',
      'delete_confirmation': 'Sind Sie sicher, dass Sie diese Notiz löschen möchten?',
      'cannot_undo': 'Diese Aktion kann nicht rückgängig gemacht werden.',
      'delete': 'Löschen',
      'note_deleted': 'Notiz gelöscht',
      'edit_text': 'Text bearbeiten',
      'copy': 'Kopieren',
      
      // Settings Page
      'settings': 'Einstellungen',
      'appearance': 'Erscheinungsbild',
      'dark_theme': 'Dunkles Design',
      'dark_theme_subtitle': 'Zwischen hellem und dunklem Design wechseln',
      'statistics': 'Statistiken',
      'total_notes': 'Gesamt Notizen',
      'days_with_notes': 'Tage mit Notizen',
      'data': 'Daten',
      'about_app': 'Über',
      'version': 'Version 1.0.0',
      'about_dialog_title': 'Über',
      'about_dialog_content': 'Captain\'s Journal\n\nEinfache App zum Führen eines Tagebuchs und von Notizen.\n\nVersion: 1.0.0',
      'close': 'Schließen',
      'language': 'Sprache',
      'language_subtitle': 'Interface-Sprache auswählen',
      'russian': 'Русский',
      'english': 'English',
      'ukrainian': 'Українська',
      'german': 'Deutsch',
      'ui': 'Benutzeroberfläche',
      'ui_subtitle': 'Einstellungen für die Anzeige der Benutzeroberfläche',
      'tab_order': 'Tab-Reihenfolge',
      'tab_order_subtitle': 'Reihenfolge ändern oder Tabs ausblenden',
      'hide_tab': 'Tab ausblenden',
      'show_tab': 'Tab anzeigen',
      'animations': 'Animationen',
      'animations_subtitle': 'Animationen in der App aktivieren oder deaktivieren',
      'enable_animations': 'Animationen aktivieren',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for convenience
  String get appTitle => translate('app_title');
  String get hintText => translate('hint_text');
  String get editNote => translate('edit_note');
  String get enterNoteText => translate('enter_note_text');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get changeDate => translate('change_date');
  String get changeTime => translate('change_time');
  String get selectDate => translate('select_date');
  String get selectTime => translate('select_time');
  String get deleteNote => translate('delete_note');
  String get deleteConfirmation => translate('delete_confirmation');
  String get cannotUndo => translate('cannot_undo');
  String get delete => translate('delete');
  String get noteDeleted => translate('note_deleted');
  String get editText => translate('edit_text');
  String get copy => translate('copy');
  String get settings => translate('settings');
  String get appearance => translate('appearance');
  String get darkTheme => translate('dark_theme');
  String get darkThemeSubtitle => translate('dark_theme_subtitle');
  String get statistics => translate('statistics');
  String get totalNotes => translate('total_notes');
  String get daysWithNotes => translate('days_with_notes');
  String get data => translate('data');
  String get aboutApp => translate('about_app');
  String get version => translate('version');
  String get aboutDialogTitle => translate('about_dialog_title');
  String get aboutDialogContent => translate('about_dialog_content');
  String get close => translate('close');
  String get language => translate('language');
  String get languageSubtitle => translate('language_subtitle');
  String get russian => translate('russian');
  String get english => translate('english');
  String get ukrainian => translate('ukrainian');
  String get german => translate('german');
  String get ui => translate('ui');
  String get uiSubtitle => translate('ui_subtitle');
  String get tabOrder => translate('tab_order');
  String get tabOrderSubtitle => translate('tab_order_subtitle');
  String get hideTab => translate('hide_tab');
  String get showTab => translate('show_tab');
  String get animations => translate('animations');
  String get animationsSubtitle => translate('animations_subtitle');
  String get enableAnimations => translate('enable_animations');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ru', 'en', 'uk', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


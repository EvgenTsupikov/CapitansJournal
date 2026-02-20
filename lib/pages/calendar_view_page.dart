// lib/pages/calendar_view_page.dart
// 
// Календарный вид заметок - отображает заметки в виде таблицы по дням месяца.
// Поддерживает навигацию по месяцам, разворачивание/сворачивание записей за день,
// копирование и редактирование заметок.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../models/command.dart';

/// Виджет календарного вида заметок.
/// 
/// Отображает заметки в виде таблицы, где каждая строка представляет день месяца.
/// Поддерживает навигацию по месяцам, разворачивание/сворачивание записей,
/// копирование и редактирование заметок.
class CalendarViewPage extends StatefulWidget {
  /// Список всех заметок для отображения
  final List<Note> notes;
  
  /// Callback для редактирования заметки
  final void Function(Note)? onEditNote;
  
  /// Callback для удаления заметки
  final void Function(Note)? onDeleteNote;
  
  /// Контроллер прокрутки для сохранения позиции
  final ScrollController? scrollController;
  
  /// Список команд для парсинга (например, #location)
  final List<Command> commands;

  const CalendarViewPage({
    super.key,
    required this.notes,
    this.onEditNote,
    this.onDeleteNote,
    this.scrollController,
    this.commands = const [],
  });

  @override
  State<CalendarViewPage> createState() => _CalendarViewPageState();
}

/// Состояние календарного вида заметок.
class _CalendarViewPageState extends State<CalendarViewPage> {
  // ─────────────────────────────────────────────
  // Константы
  // ─────────────────────────────────────────────
  
  /// Минимальная высота строки таблицы в пикселях
  static const double _minRowHeight = 55.0;
  
  /// Максимальное количество заметок, отображаемых по умолчанию
  static const int _defaultMaxNotes = 5;

  // ─────────────────────────────────────────────
  // Состояние
  // ─────────────────────────────────────────────
  
  /// Текущий отображаемый месяц
  late DateTime _currentMonth;
  
  /// Предыдущий отображаемый месяц (для отслеживания изменений)
  DateTime? _previousMonth;
  
  /// Карта развернутых дней: ключ - день (формат: "год-месяц-день"), значение - развернут ли день
  final Map<String, bool> _expandedDays = {};
  
  /// Флаг инициализации состояния для текущего месяца
  bool _isInitialized = false;
  
  /// Счетчик изменений состояния для принудительного перестроения Table
  int _stateChangeCounter = 0;

  // ─────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _previousMonth = null; // При первом запуске предыдущего месяца нет
    // Инициализируем состояние для текущего месяца (все дни свернуты)
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    for (int day = 1; day <= daysInMonth; day++) {
      final dayKey = _getDayKey(day, _currentMonth);
      _expandedDays[dayKey] = false; // Все дни свернуты по умолчанию
    }
  }

  // ─────────────────────────────────────────────
  // Утилиты для работы с датами и локализацией
  // ─────────────────────────────────────────────
  
  /// Получает код языка из текущей локали
  String _getLanguageCode() {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }
  
  /// Получает локализованную строку для календарного вида
  /// 
  /// [en] - английский вариант
  /// [ru] - русский вариант (по умолчанию)
  /// [uk] - украинский вариант (опционально)
  /// [de] - немецкий вариант (опционально)
  String _getLocalizedString({
    required String en,
    required String ru,
    String? uk,
    String? de,
  }) {
    final langCode = _getLanguageCode();
    switch (langCode) {
      case 'en':
        return en;
      case 'uk':
        return uk ?? ru;
      case 'de':
        return de ?? ru;
      default:
        return ru;
    }
  }
  
  /// Переходит к предыдущему месяцу.
  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      // Сбрасываем состояние развернутости для нового месяца
      _resetExpandedDaysForMonth(_currentMonth);
    });
  }
  
  /// Переходит к следующему месяцу.
  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      // Сбрасываем состояние развернутости для нового месяца
      _resetExpandedDaysForMonth(_currentMonth);
    });
  }
  
  /// Сбрасывает состояние развернутости для всех дней указанного месяца.
  /// 
  /// [month] - месяц, для которого нужно сбросить состояние
  void _resetExpandedDaysForMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final dayKey = _getDayKey(day, month);
      _expandedDays[dayKey] = false;
    }
  }
  
  /// Форматирует дату - возвращает только число дня.
  /// 
  /// [day] - день месяца
  /// [month] - объект DateTime с месяцем и годом (не используется, но оставлен для совместимости)
  /// Возвращает число дня с ведущим нулем (например, "05")
  String _formatDate(int day, DateTime month) {
    return day.toString().padLeft(2, '0');
  }

  /// Форматирует месяц и год для отображения в заголовке.
  /// 
  /// Поддерживает русский, английский, украинский и немецкий языки.
  /// [month] - объект DateTime с месяцем и годом
  /// Возвращает локализованную строку (например, "Декабрь 2025" или "December 2025")
  String _formatMonthYear(DateTime month) {
    final monthsRu = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthsUk = [
      'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
      'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень'
    ];
    final monthsDe = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    
    List<String> monthNames;
    switch (langCode) {
      case 'en':
        monthNames = monthsEn;
        break;
      case 'uk':
        monthNames = monthsUk;
        break;
      case 'de':
        monthNames = monthsDe;
        break;
      default: // 'ru' и другие
        monthNames = monthsRu;
        break;
    }
    
    return '${monthNames[month.month - 1]} ${month.year}';
  }
  
  /// Генерирует уникальный ключ для дня.
  /// 
  /// Используется для хранения состояния развернутости дня.
  /// [day] - день месяца
  /// [month] - объект DateTime с месяцем и годом
  /// Возвращает строку формата "год-месяц-день"
  String _getDayKey(int day, DateTime month) {
    return '${month.year}-${month.month}-$day';
  }

  // ─────────────────────────────────────────────
  // Работа с заметками
  // ─────────────────────────────────────────────
  
  /// Группирует заметки по дням месяца.
  /// 
  /// Фильтрует заметки, принадлежащие указанному месяцу,
  /// и сортирует их по времени создания в каждом дне.
  /// 
  /// [month] - месяц для группировки заметок
  /// Возвращает Map, где ключ - день месяца (1-31), значение - список заметок за этот день
  Map<int, List<Note>> _getNotesByDay(DateTime month) {
    final notesByDay = <int, List<Note>>{};
    
    // Фильтруем заметки по году и месяцу
    for (final note in widget.notes) {
      if (note.createdAt.year == month.year && 
          note.createdAt.month == month.month) {
        final day = note.createdAt.day;
        notesByDay.putIfAbsent(day, () => []).add(note);
      }
    }
    
    // Сортируем заметки по времени создания в каждом дне (от старых к новым)
    for (final dayNotes in notesByDay.values) {
      dayNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return notesByDay;
  }
  
  /// Извлекает значение команды из заметок за день.
  /// 
  /// Ищет в заметках паттерн #commandName: значение
  /// Возвращает первое найденное значение или null
  String? _extractCommandValue(List<Note> dayNotes, String commandName) {
    final pattern = RegExp('#$commandName:\\s*(.+?)(?:\\n|#|\\\$)', caseSensitive: false);
    
    for (final note in dayNotes) {
      final match = pattern.firstMatch(note.text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    
    return null;
  }

  /// Форматирует заметки за день в текстовую строку для копирования.
  /// 
  /// Каждая заметка отображается в формате "чч:мм: текст заметки".
  /// Заметки разделяются переносами строк.
  /// 
  /// [notes] - список заметок для форматирования
  /// Возвращает строку с отформатированными заметками или пустую строку, если заметок нет
  String _getNotesTextForDay(List<Note> notes) {
    if (notes.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final time = '${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}';
      buffer.write('$time: ${note.text}');
      if (i < notes.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
  
  /// Форматирует время заметки в строку "чч:мм".
  /// 
  /// [note] - заметка для форматирования времени
  /// Возвращает строку времени
  String _formatNoteTime(Note note) {
    return '${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}';
  }
  
  /// Определяет, нужно ли показывать кнопку разворачивания для дня.
  /// 
  /// Кнопка показывается для всех дней, где есть хотя бы одна запись.
  /// Это позволяет пользователю сворачивать/разворачивать записи даже если их мало.
  /// 
  /// [dayNotes] - список заметок за день
  /// Возвращает true, если нужно показать кнопку разворачивания
  bool _shouldShowExpandButton(List<Note> dayNotes) {
    return dayNotes.isNotEmpty;
  }
  
  /// Определяет, какие заметки показывать для дня.
  /// 
  /// Если день развернут, показываются все заметки.
  /// Если день свернут, показываются только первые N заметок (даже если их меньше N).
  /// 
  /// [dayNotes] - все заметки за день
  /// [isExpanded] - развернут ли день
  /// Возвращает список заметок для отображения
  List<Note> _getNotesToShow(List<Note> dayNotes, bool isExpanded) {
    if (dayNotes.isEmpty) return [];
    
    // Если день развернут, показываем ВСЕ заметки
    if (isExpanded == true) {
      debugPrint('_getNotesToShow: день развернут, показываем все ${dayNotes.length} заметок');
      return dayNotes;
    }
    
    // Если день свернут - не показываем заметки вообще (полностью скрыты)
    debugPrint('_getNotesToShow: день свернут, было ${dayNotes.length} заметок, скрываем все');
    return [];
  }

  // ─────────────────────────────────────────────
  // Построение UI
  // ─────────────────────────────────────────────
  
  /// Строит строку для одного дня (используя Row вместо TableRow).
  /// 
  /// [day] - день месяца (1-31)
  /// [month] - объект DateTime с месяцем и годом
  /// [dayNotes] - список заметок за этот день
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает Widget с Row для отображения дня
  Widget _buildDayRowWidget(
    int day,
    DateTime month,
    List<Note> dayNotes,
    bool isEnglish,
  ) {
    final dayKey = _getDayKey(day, month);
    // Просто читаем состояние - если ключа нет, значит false (свернуто)
    // НЕ инициализируем здесь, чтобы не перезаписывать состояние при каждом build
    final isExpanded = _expandedDays[dayKey] ?? false;
    debugPrint('_buildDayRowWidget: day=$day, dayKey=$dayKey, isExpanded=$isExpanded, notesCount=${dayNotes.length}');
    final hasNotes = dayNotes.isNotEmpty;
    final shouldShowExpandButton = _shouldShowExpandButton(dayNotes);
    final notesToShow = _getNotesToShow(dayNotes, isExpanded);

    return Container(
      key: ValueKey('day_${dayKey}_${isExpanded ? 'expanded' : 'collapsed'}'), // Ключ включает состояние развернутости
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Колонка с датой
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.15,
            child: _buildDateCellContent(
              day,
              month,
              shouldShowExpandButton,
              dayKey,
              isExpanded,
            ),
          ),
          // Колонка с локацией
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            child: _buildLocationCellContent(
              dayNotes,
              dayKey,
            ),
          ),
          // Колонка с заметками
          Expanded(
            child: _buildNotesCellContent(
              dayNotes,
              notesToShow,
              hasNotes,
              shouldShowExpandButton,
              isExpanded,
              dayKey,
              isEnglish,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Строит содержимое ячейки с датой.
  Widget _buildDateCellContent(
    int day,
    DateTime month,
    bool shouldShowExpandButton,
    String dayKey,
    bool isExpanded,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minRowHeight),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatDate(day, month),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (shouldShowExpandButton)
              GestureDetector(
                onTap: () {
                  // Сохраняем текущую позицию прокрутки
                  double? savedScrollPosition;
                  if (widget.scrollController != null && widget.scrollController!.hasClients) {
                    savedScrollPosition = widget.scrollController!.offset;
                  }
                  
                  setState(() {
                    final currentState = _expandedDays[dayKey] ?? false;
                    final newState = !currentState;
                    _expandedDays[dayKey] = newState;
                    _stateChangeCounter++;
                    debugPrint('Кнопка нажата: dayKey=$dayKey, было=$currentState, стало=$newState');
                  });
                  
                  // Восстанавливаем позицию прокрутки после обновления UI
                  if (savedScrollPosition != null && widget.scrollController != null && widget.scrollController!.hasClients) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (widget.scrollController != null && widget.scrollController!.hasClients) {
                        widget.scrollController!.jumpTo(savedScrollPosition!);
                      }
                    });
                  }
                },
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Строит содержимое ячейки с локацией.
  /// 
  /// Извлекает значение #location из заметок за день и отображает его.
  /// При нажатии позволяет редактировать локацию.
  Widget _buildLocationCellContent(
    List<Note> dayNotes,
    String dayKey,
  ) {
    // Ищем команду location
    final locationCommand = widget.commands.firstWhere(
      (cmd) => cmd.name.toLowerCase() == 'location',
      orElse: () => Command(name: 'location', values: []),
    );
    
    // Извлекаем значение локации из заметок
    final locationValue = _extractCommandValue(dayNotes, 'location');
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minRowHeight),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => _editLocation(dayNotes, locationValue, locationCommand),
          child: locationValue != null
              ? Text(
                  locationValue,
                  style: const TextStyle(fontSize: 12),
                )
              : Text(
                  _getLocalizedString(
                    en: 'No location',
                    ru: 'Нет локации',
                    uk: 'Немає локації',
                    de: 'Kein Ort',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ),
    );
  }
  
  /// Редактирует локацию для дня.
  /// 
  /// Показывает диалог с выбором локации из предустановленных значений
  /// или позволяет ввести новое значение.
  Future<void> _editLocation(
    List<Note> dayNotes,
    String? currentLocation,
    Command locationCommand,
  ) async {
    // Показываем диалог выбора локации
    final selectedLocation = await showDialog<String>(
      context: context,
      builder: (context) => _LocationDialog(
        currentLocation: currentLocation,
        locationCommand: locationCommand,
        isEnglish: _getLanguageCode() == 'en',
      ),
    );
    
    if (selectedLocation == null) return;
    
    // Ищем заметку с #location или создаем новую
    Note? noteWithLocation;
    for (final note in dayNotes) {
      if (note.text.contains(RegExp(r'#location:', caseSensitive: false))) {
        noteWithLocation = note;
        break;
      }
    }
    
    if (noteWithLocation != null) {
      // Обновляем существующую заметку
      final updatedText = noteWithLocation.text.replaceAll(
        RegExp(r'#location:\s*[^\n#]+', caseSensitive: false),
        '#location: $selectedLocation',
      );
      noteWithLocation.text = updatedText;
      if (widget.onEditNote != null) {
        widget.onEditNote!(noteWithLocation);
      }
    } else if (dayNotes.isNotEmpty) {
      // Добавляем #location в первую заметку дня
      final firstNote = dayNotes.first;
      firstNote.text = '#location: $selectedLocation\n${firstNote.text}';
      if (widget.onEditNote != null) {
        widget.onEditNote!(firstNote);
      }
    }
  }
  
  /// Строит содержимое ячейки со списком заметок.
  Widget _buildNotesCellContent(
    List<Note> dayNotes,
    List<Note> notesToShow,
    bool hasNotes,
    bool shouldShowExpandButton,
    bool isExpanded,
    String dayKey,
    bool isEnglish,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minRowHeight),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onLongPress: hasNotes ? () {
            _showNoteMenu(context, dayNotes);
          } : null,
          child: hasNotes
              ? _buildNotesColumn(notesToShow, shouldShowExpandButton, isExpanded, dayKey)
              : _buildEmptyNotesText(),
        ),
      ),
    );
  }
  
  /// Строит ячейку с датой и кнопкой разворачивания.
  /// 
  /// [day] - день месяца
  /// [month] - объект DateTime с месяцем и годом
  /// [shouldShowExpandButton] - показывать ли кнопку разворачивания
  /// [dayKey] - уникальный ключ дня
  /// [isExpanded] - развернут ли день
  /// Возвращает TableCell с датой
  TableCell _buildDateCell(
    int day,
    DateTime month,
    bool shouldShowExpandButton,
    String dayKey,
    bool isExpanded,
  ) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.top,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minRowHeight),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  _formatDate(day, month),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (shouldShowExpandButton)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Явно переключаем состояние
                      final currentState = _expandedDays[dayKey] ?? false;
                      _expandedDays[dayKey] = !currentState;
                      _stateChangeCounter++; // Увеличиваем счетчик для принудительного перестроения
                    });
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Строит ячейку со списком заметок.
  /// 
  /// [dayNotes] - все заметки за день
  /// [notesToShow] - заметки для отображения
  /// [hasNotes] - есть ли заметки
  /// [shouldShowExpandButton] - показывать ли кнопку разворачивания
  /// [isExpanded] - развернут ли день
  /// [dayKey] - уникальный ключ дня
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает TableCell со списком заметок
  TableCell _buildNotesCell(
    List<Note> dayNotes,
    List<Note> notesToShow,
    bool hasNotes,
    bool shouldShowExpandButton,
    bool isExpanded,
    String dayKey,
    bool isEnglish,
  ) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.top,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minRowHeight),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onLongPress: hasNotes ? () {
              _showNoteMenu(context, dayNotes);
            } : null,
            child: hasNotes
                ? _buildNotesColumn(notesToShow, shouldShowExpandButton, isExpanded, dayKey)
                : _buildEmptyNotesText(),
          ),
        ),
      ),
    );
  }
  
  /// Строит колонку со списком заметок.
  /// 
  /// [notesToShow] - заметки для отображения
  /// [shouldShowExpandButton] - показывать ли кнопку "Показать все"
  /// [isExpanded] - развернут ли день
  /// [dayKey] - уникальный ключ дня
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает Column со списком заметок
  Widget _buildNotesColumn(
    List<Note> notesToShow,
    bool shouldShowExpandButton,
    bool isExpanded,
    String dayKey,
  ) {
    debugPrint('_buildNotesColumn: dayKey=$dayKey, isExpanded=$isExpanded, notesToShow.length=${notesToShow.length}');
    return Column(
      key: ValueKey('notes_column_$dayKey${isExpanded ? '_expanded' : '_collapsed'}'), // Ключ включает состояние
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Показываем заметки только если день развернут
        if (isExpanded)
          ...notesToShow.asMap().entries.map((entry) {
            final index = entry.key;
            final note = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < notesToShow.length - 1 ? 8 : 0,
              ),
              child: Text(
                '${_formatNoteTime(note)}: ${note.text}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }),
        // Кнопка "Показать все" показывается только если день свернут
        if (shouldShowExpandButton && !isExpanded)
          _buildShowAllButton(dayKey),
        // Кнопка "Свернуть" показывается только если день развернут
        if (shouldShowExpandButton && isExpanded)
          _buildCollapseButton(dayKey),
      ],
    );
  }
  
  /// Строит кнопку "Показать все".
  /// 
  /// [dayKey] - уникальный ключ дня
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает Widget с кнопкой
  Widget _buildShowAllButton(String dayKey) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () {
          // Сохраняем текущую позицию прокрутки
          double? savedScrollPosition;
          if (widget.scrollController != null && widget.scrollController!.hasClients) {
            savedScrollPosition = widget.scrollController!.offset;
          }
          
          setState(() {
            debugPrint('_buildShowAllButton: нажата кнопка "Show all" для dayKey=$dayKey');
            _expandedDays[dayKey] = true;
            _stateChangeCounter++; // Увеличиваем счетчик для принудительного перестроения
            debugPrint('_buildShowAllButton: состояние обновлено, _expandedDays[$dayKey]=${_expandedDays[dayKey]}');
          });
          
          // Восстанавливаем позицию прокрутки после обновления UI
          if (savedScrollPosition != null && widget.scrollController != null && widget.scrollController!.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (widget.scrollController != null && widget.scrollController!.hasClients) {
                widget.scrollController!.jumpTo(savedScrollPosition!);
              }
            });
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.expand_more,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _getLocalizedString(
                en: 'Show all',
                ru: 'Показать все',
                uk: 'Показати все',
                de: 'Alle anzeigen',
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Строит кнопку "Свернуть".
  /// 
  /// [dayKey] - уникальный ключ дня
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает Widget с кнопкой
  Widget _buildCollapseButton(String dayKey) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () {
          // Сохраняем текущую позицию прокрутки и максимальную позицию ДО сворачивания
          double? savedScrollPosition;
          double? savedMaxScroll;
          if (widget.scrollController != null && widget.scrollController!.hasClients) {
            savedScrollPosition = widget.scrollController!.offset;
            savedMaxScroll = widget.scrollController!.position.maxScrollExtent;
          }
          
          setState(() {
            debugPrint('_buildCollapseButton: нажата кнопка "Collapse" для dayKey=$dayKey');
            _expandedDays[dayKey] = false;
            _stateChangeCounter++; // Увеличиваем счетчик для принудительного перестроения
            debugPrint('_buildCollapseButton: состояние обновлено, _expandedDays[$dayKey]=${_expandedDays[dayKey]}');
          });
          
          // Восстанавливаем позицию прокрутки после обновления UI
          // При сворачивании контент уменьшается, поэтому нужно пересчитать позицию пропорционально
          if (savedScrollPosition != null && savedMaxScroll != null && widget.scrollController != null && widget.scrollController!.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Ждем еще один кадр для полного завершения перестроения
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.scrollController != null && widget.scrollController!.hasClients) {
                  final newMaxScroll = widget.scrollController!.position.maxScrollExtent;
                  
                  // Если максимальная позиция изменилась (контент уменьшился), пересчитываем позицию пропорционально
                  double targetPosition;
                  if (savedMaxScroll! > 0 && newMaxScroll < savedMaxScroll!) {
                    // Контент уменьшился - пересчитываем позицию пропорционально
                    final ratio = newMaxScroll / savedMaxScroll!;
                    targetPosition = savedScrollPosition! * ratio;
                    // Ограничиваем максимальной позицией
                    targetPosition = targetPosition > newMaxScroll ? newMaxScroll : targetPosition;
                  } else {
                    // Контент не уменьшился или увеличился - используем сохраненную позицию
                    targetPosition = savedScrollPosition! > newMaxScroll ? newMaxScroll : savedScrollPosition!;
                  }
                  
                  widget.scrollController!.jumpTo(targetPosition);
                }
              });
            });
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.expand_less,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _getLocalizedString(
                en: 'Collapse',
                ru: 'Свернуть',
                uk: 'Згорнути',
                de: 'Einklappen',
              ),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Строит текст для пустого дня.
  /// 
  /// [isEnglish] - использовать ли английский язык
  /// Возвращает Widget с текстом "Нет записей"
  Widget _buildEmptyNotesText() {
    return Text(
      _getLocalizedString(
        en: 'No notes',
        ru: 'Нет записей',
        uk: 'Немає записів',
        de: 'Keine Notizen',
      ),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }
  
  /// Строит таблицу календаря для указанного месяца.
  /// 
  /// [month] - месяц для отображения
  /// Возвращает Widget с таблицей календаря
  Widget _buildCalendarTable(DateTime month) {
    final notesByDay = _getNotesByDay(month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Проверяем, изменился ли месяц
    final monthKey = '${month.year}-${month.month}';
    final previousMonthKey = _previousMonth != null ? '${_previousMonth!.year}-${_previousMonth!.month}' : null;
    
    // Если месяц изменился - сбрасываем состояние для всех дней нового месяца
    if (monthKey != previousMonthKey) {
      debugPrint('_buildCalendarTable: месяц изменился, сбрасываем состояние для всех дней');
      for (int day = 1; day <= daysInMonth; day++) {
        final dayKey = _getDayKey(day, month);
        _expandedDays[dayKey] = false; // Все дни свернуты по умолчанию
        debugPrint('_buildCalendarTable: инициализирован день $dayKey = false');
      }
      _previousMonth = DateTime(month.year, month.month, 1);
    } else {
      // Месяц не изменился - инициализируем только новые дни (если их нет)
      for (int day = 1; day <= daysInMonth; day++) {
        final dayKey = _getDayKey(day, month);
        if (!_expandedDays.containsKey(dayKey)) {
          _expandedDays[dayKey] = false; // Новые дни тоже свернуты
          debugPrint('_buildCalendarTable: инициализирован новый день $dayKey = false');
        }
      }
    }

    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Column(
      children: [
        // Заголовок
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    isEnglish ? 'Date' : 'Дата',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _getLocalizedString(
                      en: 'Location',
                      ru: 'Локация',
                      uk: 'Локація',
                      de: 'Ort',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _getLocalizedString(
                      en: 'Daily Log',
                      ru: 'КЖ лог',
                      uk: 'Щоденний лог',
                      de: 'Tageslog',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Строки данных - используем ListView.builder для гарантированного перестроения
        Expanded(
          child: ListView.builder(
            key: ValueKey('calendar_list_${month.year}_${month.month}_$_stateChangeCounter'), // Ключ меняется при изменении состояния
            controller: widget.scrollController,
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              return _buildDayRowWidget(
                day,
                month,
                notesByDay[day] ?? [],
                isEnglish,
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Диалоги и меню
  // ─────────────────────────────────────────────
  
  /// Показывает меню действий для заметок за день.
  /// 
  /// Поддерживает редактирование (для одной заметки), копирование и удаление.
  /// 
  /// [context] - контекст для показа диалога
  /// [notes] - список заметок за день
  /// [isEnglish] - использовать ли английский язык
  void _showNoteMenu(BuildContext context, List<Note> notes) {
    if (notes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (notes.length == 1)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(_getLocalizedString(
                  en: 'Edit',
                  ru: 'Редактировать',
                  uk: 'Редагувати',
                  de: 'Bearbeiten',
                )),
                onTap: () {
                  Navigator.pop(context);
                  if (widget.onEditNote != null) {
                    widget.onEditNote!(notes[0]);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(_getLocalizedString(
                en: 'Copy',
                ru: 'Копировать',
                uk: 'Копіювати',
                de: 'Kopieren',
              )),
              onTap: () {
                Navigator.pop(context);
                final text = _getNotesTextForDay(notes);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getLocalizedString(
                      en: 'Copied to clipboard',
                      ru: 'Скопировано в буфер обмена',
                      uk: 'Скопійовано в буфер обміну',
                      de: 'In Zwischenablage kopiert',
                    )),
                  ),
                );
              },
            ),
            if (notes.length == 1 && widget.onDeleteNote != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  _getLocalizedString(
                    en: 'Delete',
                    ru: 'Удалить',
                    uk: 'Видалити',
                    de: 'Löschen',
                  ),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDeleteNote!(notes[0]);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';

    return Scaffold(
      body: Column(
        children: [
          // Кнопки навигации по месяцам
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  _formatMonthYear(_currentMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Таблица с записями
          Expanded(
            child: _buildCalendarTable(_currentMonth),
          ),
        ],
      ),
    );
  }
}

/// Диалог для выбора локации с иерархической структурой (страна -> город -> локация).
class _LocationDialog extends StatefulWidget {
  final String? currentLocation;
  final Command locationCommand;
  final bool isEnglish;

  const _LocationDialog({
    required this.currentLocation,
    required this.locationCommand,
    required this.isEnglish,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  LocationValue? _selectedCountry;
  LocationValue? _selectedCity;
  LocationValue? _selectedLocation;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController(text: widget.currentLocation ?? '');
    // Парсим текущую локацию, если она есть
    if (widget.currentLocation != null) {
      _parseCurrentLocation(widget.currentLocation!);
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _parseCurrentLocation(String location) {
    // Пытаемся найти локацию в иерархической структуре
    for (final country in widget.locationCommand.values) {
      if (location.contains(country.name)) {
        _selectedCountry = country;
        for (final city in country.children) {
          if (location.contains(city.name)) {
            _selectedCity = city;
            for (final loc in city.children) {
              if (location.contains(loc.name)) {
                _selectedLocation = loc;
                break;
              }
            }
            break;
          }
        }
        break;
      }
    }
  }

  String? _getSelectedPath() {
    if (_selectedLocation != null && _selectedCity != null && _selectedCountry != null) {
      return '${_selectedCountry!.name} > ${_selectedCity!.name} > ${_selectedLocation!.name}';
    } else if (_selectedCity != null && _selectedCountry != null) {
      return '${_selectedCountry!.name} > ${_selectedCity!.name}';
    } else if (_selectedCountry != null) {
      return _selectedCountry!.name;
    } else if (_customController.text.trim().isNotEmpty) {
      return _customController.text.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEnglish ? 'Select Location' : 'Выберите локацию'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор страны
              Text(
                widget.isEnglish ? 'Country:' : 'Страна:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...widget.locationCommand.values.map((country) {
                return RadioListTile<LocationValue>(
                  title: Text(country.name),
                  value: country,
                  groupValue: _selectedCountry,
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedCity = null;
                      _selectedLocation = null;
                    });
                  },
                );
              }),
              
              // Выбор города (если выбрана страна)
              if (_selectedCountry != null && _selectedCountry!.children.isNotEmpty) ...[
                const Divider(),
                Text(
                  widget.isEnglish ? 'City:' : 'Город:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._selectedCountry!.children.map((city) {
                  return RadioListTile<LocationValue>(
                    title: Text(city.name),
                    value: city,
                    groupValue: _selectedCity,
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _selectedLocation = null;
                      });
                    },
                  );
                }),
              ],
              
              // Выбор конкретной локации (если выбран город)
              if (_selectedCity != null && _selectedCity!.children.isNotEmpty) ...[
                const Divider(),
                Text(
                  widget.isEnglish ? 'Location:' : 'Локация:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._selectedCity!.children.map((location) {
                  return RadioListTile<LocationValue>(
                    title: Text(location.name),
                    value: location,
                    groupValue: _selectedLocation,
                    onChanged: (value) {
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                  );
                }),
              ],
              
              const Divider(),
              // Поле для ввода произвольного значения
              TextField(
                controller: _customController,
                decoration: InputDecoration(
                  labelText: widget.isEnglish ? 'Custom location' : 'Произвольная локация',
                  hintText: widget.isEnglish ? 'Enter location' : 'Введите локацию',
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.trim().isNotEmpty) {
                      _selectedCountry = null;
                      _selectedCity = null;
                      _selectedLocation = null;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isEnglish ? 'Cancel' : 'Отмена'),
        ),
        TextButton(
          onPressed: _getSelectedPath() != null
              ? () => Navigator.pop(context, _getSelectedPath())
              : null,
          child: Text(widget.isEnglish ? 'Save' : 'Сохранить'),
        ),
      ],
    );
  }
}


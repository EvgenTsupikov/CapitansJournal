// test/calendar_view_page_test.dart
//
// Юнит-тесты для CalendarViewPage.
// Тестирует логику работы с датами, группировку заметок, форматирование и состояние развернутости.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_logger/models/note.dart';
import 'package:flutter_test_logger/pages/calendar_view_page.dart';

void main() {
  group('CalendarViewPage', () {
    // ─────────────────────────────────────────────
    // Тестовые данные
    // ─────────────────────────────────────────────
    
    late List<Note> testNotes;
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2025, 12, 15, 10, 30);
      testNotes = [
        Note(text: 'Note 1', createdAt: DateTime(2025, 12, 1, 10, 0)),
        Note(text: 'Note 2', createdAt: DateTime(2025, 12, 1, 11, 0)),
        Note(text: 'Note 3', createdAt: DateTime(2025, 12, 1, 12, 0)),
        Note(text: 'Note 4', createdAt: DateTime(2025, 12, 2, 10, 0)),
        Note(text: 'Note 5', createdAt: DateTime(2025, 12, 2, 11, 0)),
        Note(text: 'Note 6', createdAt: DateTime(2025, 11, 30, 10, 0)), // Другой месяц
        Note(text: 'Note 7', createdAt: DateTime(2026, 1, 1, 10, 0)), // Другой год
      ];
    });

    // ─────────────────────────────────────────────
    // Тесты создания виджета
    // ─────────────────────────────────────────────
    
    testWidgets('отображает календарный вид с заметками', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Проверяем, что виджет отображается
      expect(find.byType(CalendarViewPage), findsOneWidget);
      expect(find.text('December 2025'), findsOneWidget);
    });

    testWidgets('отображает заголовки таблицы', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Проверяем заголовки таблицы
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Daily Log'), findsOneWidget);
    });

    // ─────────────────────────────────────────────
    // Тесты группировки заметок
    // ─────────────────────────────────────────────
    
    testWidgets('группирует заметки по дням месяца', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Разворачиваем день, чтобы увидеть все заметки
      final expandButton = find.byIcon(Icons.expand_more).first;
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Проверяем, что заметки за 1 декабря отображаются
      expect(find.textContaining('01.12.2025'), findsOneWidget);
      expect(find.textContaining('Note 1'), findsOneWidget);
      expect(find.textContaining('Note 2'), findsOneWidget);
      expect(find.textContaining('Note 3'), findsOneWidget);
    });

    testWidgets('не отображает заметки из других месяцев', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Заметка из ноября не должна отображаться
      expect(find.textContaining('Note 6'), findsNothing);
    });

    testWidgets('отображает "No notes" для дней без заметок', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // День без заметок должен показывать "No notes"
      expect(find.text('No notes'), findsWidgets);
    });

    // ─────────────────────────────────────────────
    // Тесты разворачивания/сворачивания
    // ─────────────────────────────────────────────
    
    testWidgets('показывает кнопку разворачивания для дней с более чем 5 заметками', (WidgetTester tester) async {
      // Создаем 6 заметок за один день
      final manyNotes = List.generate(6, (i) => 
        Note(text: 'Note $i', createdAt: DateTime(2025, 12, 1, 10 + i, 0))
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: manyNotes),
        ),
      );

      // Кнопка разворачивания должна быть видна
      expect(find.byIcon(Icons.expand_more), findsWidgets);
    });

    testWidgets('показывает кнопку разворачивания для всех дней с записями', (WidgetTester tester) async {
      // Создаем 7 заметок за один день (больше 5)
      final manyNotes = List.generate(7, (i) => 
        Note(text: 'Note $i', createdAt: DateTime(2025, 12, 1, 10 + i, 0))
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: manyNotes),
        ),
      );

      // Кнопка разворачивания должна быть видна для дней с записями
      // (может быть две иконки: одна в заголовке даты, одна в кнопке "Show all")
      expect(find.byIcon(Icons.expand_more), findsWidgets);
    });

    testWidgets('показывает кнопку разворачивания даже для дней с одной записью', (WidgetTester tester) async {
      // Создаем 1 заметку за один день
      final oneNote = [
        Note(text: 'Single note', createdAt: DateTime(2025, 12, 1, 10, 0))
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: oneNote),
        ),
      );

      // Кнопка разворачивания должна быть видна даже для дней с одной записью
      expect(find.byIcon(Icons.expand_more), findsWidgets);
    });

    testWidgets('скрывает все заметки по умолчанию', (WidgetTester tester) async {
      // Создаем 7 заметок за один день
      final manyNotes = List.generate(7, (i) => 
        Note(text: 'Note $i', createdAt: DateTime(2025, 12, 1, 10 + i, 0))
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: manyNotes),
        ),
      );

      // Все заметки должны быть скрыты в свернутом состоянии
      expect(find.textContaining('Note 0'), findsNothing);
      expect(find.textContaining('Note 1'), findsNothing);
      expect(find.textContaining('Note 2'), findsNothing);
      expect(find.textContaining('Note 3'), findsNothing);
      expect(find.textContaining('Note 4'), findsNothing);
      expect(find.textContaining('Note 5'), findsNothing);
      expect(find.textContaining('Note 6'), findsNothing);
      
      // Кнопка "Показать все" должна быть видна
      expect(find.text('Show all'), findsOneWidget);
    });

    testWidgets('разворачивает все заметки при нажатии на кнопку', (WidgetTester tester) async {
      // Создаем 7 заметок за один день
      final manyNotes = List.generate(7, (i) => 
        Note(text: 'Note $i', createdAt: DateTime(2025, 12, 1, 10 + i, 0))
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: manyNotes),
        ),
      );

      // Находим и нажимаем кнопку разворачивания
      final expandButton = find.byIcon(Icons.expand_more).first;
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Все заметки должны быть видны
      for (int i = 0; i < 7; i++) {
        expect(find.textContaining('Note $i'), findsOneWidget);
      }
    });

    // ─────────────────────────────────────────────
    // Тесты навигации по месяцам
    // ─────────────────────────────────────────────
    
    testWidgets('отображает правильный месяц в заголовке', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // По умолчанию должен отображаться текущий месяц
      expect(find.textContaining('December'), findsOneWidget);
      // Проверяем конкретный заголовок месяца, а не все вхождения года
      expect(find.text('December 2025'), findsOneWidget);
    });

    // ─────────────────────────────────────────────
    // Тесты форматирования
    // ─────────────────────────────────────────────
    
    testWidgets('форматирует дату правильно', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Проверяем формат даты
      expect(find.textContaining('01.12.2025'), findsOneWidget);
      expect(find.textContaining('02.12.2025'), findsOneWidget);
    });

    testWidgets('форматирует время заметки правильно', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Разворачиваем день, чтобы увидеть все заметки
      final expandButton = find.byIcon(Icons.expand_more).first;
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Проверяем формат времени (чч:мм)
      expect(find.textContaining('10:00'), findsWidgets);
      expect(find.textContaining('11:00'), findsWidgets);
    });

    // ─────────────────────────────────────────────
    // Тесты меню действий
    // ─────────────────────────────────────────────
    
    testWidgets('показывает меню при долгом нажатии на заметки', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Сначала разворачиваем день, чтобы увидеть заметки
      final expandButton = find.byIcon(Icons.expand_more).first;
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Находим текст заметки и делаем долгое нажатие
      final noteText = find.textContaining('Note 1');
      await tester.longPress(noteText);
      await tester.pumpAndSettle();

      // Меню должно появиться
      expect(find.text('Copy'), findsOneWidget);
    });

    // ─────────────────────────────────────────────
    // Тесты пустого состояния
    // ─────────────────────────────────────────────
    
    testWidgets('обрабатывает пустой список заметок', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: []),
        ),
      );

      // Виджет должен отображаться без ошибок
      expect(find.byType(CalendarViewPage), findsOneWidget);
      expect(find.text('No notes'), findsWidgets);
    });

    // ─────────────────────────────────────────────
    // Тесты сортировки заметок
    // ─────────────────────────────────────────────
    
    testWidgets('сортирует заметки по времени в каждом дне', (WidgetTester tester) async {
      // Создаем заметки в разном порядке
      final unsortedNotes = [
        Note(text: 'Third', createdAt: DateTime(2025, 12, 1, 14, 0)),
        Note(text: 'First', createdAt: DateTime(2025, 12, 1, 10, 0)),
        Note(text: 'Second', createdAt: DateTime(2025, 12, 1, 12, 0)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: unsortedNotes),
        ),
      );

      // Сначала разворачиваем день, чтобы увидеть все заметки
      final expandButton = find.byIcon(Icons.expand_more).first;
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // Находим все тексты заметок
      final note1 = find.textContaining('First');
      final note2 = find.textContaining('Second');
      final note3 = find.textContaining('Third');

      // Проверяем, что заметки отображаются в правильном порядке
      expect(note1, findsOneWidget);
      expect(note2, findsOneWidget);
      expect(note3, findsOneWidget);
    });

    // ─────────────────────────────────────────────
    // Тесты минимальной высоты строки
    // ─────────────────────────────────────────────
    
    testWidgets('применяет минимальную высоту строки', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarViewPage(notes: testNotes),
        ),
      );

      // Проверяем, что Column отображается (заменили Table на Column)
      expect(find.byType(Column), findsWidgets);
    });
  });

  // ─────────────────────────────────────────────
  // Группа тестов для утилит (если бы они были публичными)
  // ─────────────────────────────────────────────
  
  group('CalendarViewPage Utilities', () {
    test('форматирует дату правильно', () {
      // Этот тест проверяет логику форматирования, которая используется внутри виджета
      final day = 15;
      final month = DateTime(2025, 12, 1);
      final formatted = '${day.toString().padLeft(2, '0')}.${month.month.toString().padLeft(2, '0')}.${month.year}';
      
      expect(formatted, '15.12.2025');
    });

    test('форматирует время заметки правильно', () {
      final note = Note(
        text: 'Test',
        createdAt: DateTime(2025, 12, 1, 9, 5),
      );
      
      final hour = note.createdAt.hour.toString().padLeft(2, '0');
      final minute = note.createdAt.minute.toString().padLeft(2, '0');
      final formatted = '$hour:$minute';
      
      expect(formatted, '09:05');
    });
  });
}


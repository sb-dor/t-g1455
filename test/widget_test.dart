import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:t_g1455/main.dart';

void main() {
  testWidgets('shows an empty todo list with an add action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('adds a task from the glass editor sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('New task'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('task-title-field')),
      'Buy groceries',
    );
    await tester.pump();
    await tester.tap(find.text('Add task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });

  testWidgets('completes a task and filters open and done views', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey<String>('task-title-field')),
      'Ship the app',
    );
    await tester.pump();
    await tester.tap(find.text('Add task'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byKey(const ValueKey<String>('todo-toggle-1')));
    await tester.pump();

    expect(find.text('1 of 1 complete'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('No open tasks'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(find.text('Ship the app'), findsOneWidget);
  });

  testWidgets('searches tasks by title', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await _addTask(tester, 'Buy groceries');
    await _addTask(tester, 'Call the dentist');

    await tester.enterText(
      find.byKey(const ValueKey<String>('task-search-field')),
      'grocer',
    );
    await tester.pump();

    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Call the dentist'), findsNothing);
  });

  testWidgets('sorts tasks and hides completed tasks from the popover', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    await _addTask(tester, 'Apple');
    await _addTask(tester, 'Zulu');
    await tester.tap(find.byKey(const ValueKey<String>('todo-toggle-1')));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('filter-popover-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Sort tasks'), findsOneWidget);

    await tester.tap(find.text('A–Z'));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('Apple')).dy,
      lessThan(tester.getTopLeft(find.text('Zulu')).dy),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('show-completed-switch')),
    );
    await tester.pump();

    expect(find.text('Apple'), findsNothing);
    expect(find.text('Zulu'), findsOneWidget);
  });

  testWidgets('deletes a task after glass confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    await _addTask(tester, 'Read a book');

    await tester.tap(find.byKey(const ValueKey<String>('task-menu-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Delete "Read a book"?'), findsOneWidget);

    await tester.tap(find.text('Delete').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Read a book'), findsNothing);
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('edits a task by tapping its content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    await _addTask(tester, 'Old title');

    await tester.tap(find.byKey(const ValueKey<String>('edit-task-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('task-title-field')),
      'New title',
    );
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Old title'), findsNothing);
    expect(find.text('New title'), findsOneWidget);
  });

  testWidgets('clears completed tasks from the glass action group', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    await _addTask(tester, 'Finished task');
    await tester.tap(find.byKey(const ValueKey<String>('todo-toggle-1')));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.cleaning_services_outlined));
    await tester.pump();

    expect(find.text('Finished task'), findsNothing);
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}

Future<void> _addTask(WidgetTester tester, String title) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(
    find.byKey(const ValueKey<String>('task-title-field')),
    title,
  );
  await tester.pump();
  await tester.tap(find.text('Add task'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

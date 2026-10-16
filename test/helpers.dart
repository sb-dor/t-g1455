import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:t_g1455/main.dart';
import 'package:t_g1455/todo_controller.dart';

Future<void> pumpApp(WidgetTester tester, {TodoController? controller}) async {
  await tester.pumpWidget(App(controller: controller));
  await tester.pump();
}

Future<void> addTask(WidgetTester tester, String title) async {
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

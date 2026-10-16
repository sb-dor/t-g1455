import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1455/g1455.dart';

import 'helpers.dart';

Future<void> _openEditor(WidgetTester tester) async {
  await pumpApp(tester);
  await addTask(tester, 'Write report');
  await tester.tap(find.byKey(const ValueKey<String>('edit-task-1')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Offset _plus(WidgetTester tester) =>
    tester
        .getRect(find.byKey(const ValueKey<String>('estimate-stepper')))
        .centerRight -
    const Offset(12, 0);

void main() {
  testWidgets('stepper sets the estimate', (WidgetTester tester) async {
    await _openEditor(tester);

    expect(find.text('Estimate: 1 pomodoro'), findsOneWidget);

    await tester.tapAt(_plus(tester));
    await tester.pump();
    await tester.tapAt(_plus(tester));
    await tester.pump();

    expect(find.text('Estimate: 3 pomodoros'), findsOneWidget);

    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('3 pomodoros'), findsOneWidget);
  });

  testWidgets('stepper stops at 10', (WidgetTester tester) async {
    await _openEditor(tester);

    for (int i = 0; i < 12; i++) {
      await tester.tapAt(_plus(tester));
      await tester.pump();
    }

    expect(find.text('Estimate: 10 pomodoros'), findsOneWidget);
  });

  testWidgets('priority blobs select the priority', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    await tester.tap(find.byKey(const ValueKey<String>('priority-blob-high')));
    await tester.pump();

    expect(find.text('High priority'), findsOneWidget);
  });

  testWidgets('priority blobs fuse only with the selected blob', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    final double spacing = tester
        .widget<GlassGroup>(find.byType(GlassGroup))
        .spacing;
    const List<String> names = <String>['low', 'medium', 'high'];
    Rect blob(String name) => tester.getRect(
      find.descendant(
        of: find.byKey(ValueKey<String>('priority-blob-$name')),
        matching: find.byType(GlassSurface),
      ),
    );

    for (final String selected in names) {
      await tester.tap(find.byKey(ValueKey<String>('priority-blob-$selected')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      for (int i = 0; i < names.length - 1; i++) {
        final double gap = blob(names[i + 1]).left - blob(names[i]).right;
        final bool touchesSelected =
            names[i] == selected || names[i + 1] == selected;
        expect(
          gap <= spacing,
          touchesSelected,
          reason:
              '${names[i]} to ${names[i + 1]} with $selected selected: gap '
              '$gap against GlassGroup spacing $spacing',
        );
      }
    }
  });

  testWidgets('editor pulls up to the large detent', (
    WidgetTester tester,
  ) async {
    await _openEditor(tester);

    final double y0 = tester.getTopLeft(find.text('Edit task')).dy;
    await tester.drag(find.text('Edit task'), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.getTopLeft(find.text('Edit task')).dy, lessThan(y0 - 100));
  });

  testWidgets('fields use the concentric radius', (WidgetTester tester) async {
    await _openEditor(tester);

    final InputDecorationThemeData fields = Theme.of(
      tester.element(find.byKey(const ValueKey<String>('task-title-field'))),
    ).inputDecorationTheme;

    expect(
      (fields.border! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(GlassConcentric.radius(kGlassSheetRadius, 20)),
    );
  });
}

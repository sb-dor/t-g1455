import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_item.dart';

import 'helpers.dart';

const ValueKey<String> _nextUpKey = ValueKey<String>('next-up-accessory');

TodoController _seeded(List<String> titles) {
  final TodoController controller = TodoController();
  for (final String title in titles) {
    controller.addTask(title: title);
  }
  return controller;
}

/// Every label in the live semantics tree.
Set<String> _semanticLabels(WidgetTester tester) {
  final Set<String> labels = <String>{};
  void visit(SemanticsNode node) {
    labels.add(node.label);
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester
        .renderObject(find.byType(GlassTabBar))
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return labels;
}

void main() {
  testWidgets('next up shows the first open task', (WidgetTester tester) async {
    final TodoController c = _seeded(<String>['Zulu', 'Apple']);
    addTearDown(c.dispose);

    await pumpApp(tester, controller: c);

    expect(find.text('Next up: Apple'), findsOneWidget);
  });

  testWidgets('next up follows completion and deletion', (
    WidgetTester tester,
  ) async {
    final TodoController c = _seeded(<String>['Zulu', 'Apple']);
    addTearDown(c.dispose);
    await pumpApp(tester, controller: c);

    c.setCompleted(2, true);
    await tester.pump();

    expect(find.text('Next up: Zulu'), findsOneWidget);

    c.deleteTask(1);
    await tester.pump();

    expect(find.byKey(_nextUpKey), findsNothing);
  });

  testWidgets('long next-up titles stay on one line', (
    WidgetTester tester,
  ) async {
    final TodoController c = _seeded(<String>['x' * 200]);
    addTearDown(c.dispose);

    await pumpApp(tester, controller: c);

    expect(tester.takeException(), isNull);
    final Text text = tester.widget<Text>(find.byKey(_nextUpKey));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('tab bar is not rebuilt when its inputs are unchanged', (
    WidgetTester tester,
  ) async {
    final TodoController c = _seeded(<String>['A']);
    addTearDown(c.dispose);
    await pumpApp(tester, controller: c);
    final GlassTabBar before = tester.widget(find.byType(GlassTabBar));

    c.updateTask(
      1,
      title: 'A',
      notes: 'note',
      priority: TodoPriority.medium,
      estimate: 1,
    );
    await tester.pump();

    expect(identical(before, tester.widget(find.byType(GlassTabBar))), isTrue);
  });

  testWidgets('tab bar collapses on scroll down', (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final TodoController c = _seeded(<String>[
      for (int i = 0; i < 20; i++) 'Task $i',
    ]);
    addTearDown(c.dispose);
    await pumpApp(tester, controller: c);

    // Collapsing keeps the labels in the tree (faded out under an Opacity and
    // excluded from semantics) rather than removing them, so "collapsed" is
    // read off what the bar draws and says: label opacity and the one
    // button a screen reader hears. The extra bare pump starts the spring's
    // ticker; its first frame has zero elapsed time.
    double labelOpacity() => tester
        .widget<Opacity>(
          find.ancestor(of: find.text('All'), matching: find.byType(Opacity)),
        )
        .opacity;

    expect(labelOpacity(), 1);
    expect(_semanticLabels(tester), contains('Open'));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(labelOpacity(), 0);
    expect(_semanticLabels(tester), isNot(contains('Open')));
    expect(_semanticLabels(tester), contains('All'));

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(labelOpacity(), 1);
    expect(find.text('All'), findsOneWidget);
    expect(_semanticLabels(tester), contains('Open'));

    semantics.dispose();
  });
}

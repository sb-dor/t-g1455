import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/widgets/todo_row.dart';

import 'helpers.dart';

ValueKey<String> _key(String name) => ValueKey<String>(name);

Future<void> _openLab(WidgetTester tester) async {
  await tester.tap(find.byKey(_key('lab-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _closeLab(WidgetTester tester) async {
  Navigator.of(tester.element(find.text('Glass Lab'))).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(_key(key)));
  await tester.pump();
  await tester.tap(find.byKey(_key(key)));
  await tester.pump();
}

void main() {
  testWidgets('lab badge follows changes', (WidgetTester tester) async {
    await pumpApp(tester);

    bool badgeVisible() =>
        tester.widget<GlassBadge>(find.byKey(_key('lab-badge'))).isVisible;

    expect(badgeVisible(), isFalse);

    await _openLab(tester);
    await _tap(tester, 'lab-ripple');
    expect(badgeVisible(), isTrue);

    await _tap(tester, 'lab-reset');
    expect(badgeVisible(), isFalse);

    await _closeLab(tester);
  });

  testWidgets('lab switches reach the host', (WidgetTester tester) async {
    await pumpApp(tester);
    await _openLab(tester);

    await _tap(tester, 'lab-reduce-transparency');
    await tester.pump();
    await tester.pump();

    expect(
      GlassTheme.of(tester.element(find.text('Glass Lab'))).tier.tier,
      GlassTier.opaque,
    );

    await _closeLab(tester);
  });

  testWidgets('ledger reads the glass on screen', (WidgetTester tester) async {
    await pumpApp(tester);
    await _openLab(tester);
    await tester.pump(const Duration(milliseconds: 1100));

    final String text = tester
        .widget<Text>(find.byKey(_key('lab-ledger')))
        .data!;
    expect(
      text,
      matches(
        RegExp(r'^\d+ surfaces · \d+ captured · \d+\.\d\d screens · \w+$'),
      ),
    );

    await _closeLab(tester);
  });

  testWidgets('glass rows turn rows into glass cards', (
    WidgetTester tester,
  ) async {
    final TodoController controller = TodoController()
      ..addTask(title: 'Glassy');
    await pumpApp(
      tester,
      controller: controller,
      lab: LabSettings()..setGlassRows(true),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(TodoRow),
        matching: find.byType(GlassCard),
      ),
      findsOneWidget,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';
import 'package:t_g1455/widgets/todo_backdrop.dart';

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

void main() {
  test('light theme is off by default and is not a Lab change', () {
    final LabSettings lab = LabSettings();
    addTearDown(lab.dispose);

    expect(lab.lightTheme, isFalse);
    expect(lab.brightness, Brightness.dark);

    lab.setLightTheme(true);
    expect(lab.lightTheme, isTrue);
    expect(lab.brightness, Brightness.light);
    expect(lab.hasChanges, isFalse);

    lab
      ..setRipple(true)
      ..reset();
    expect(lab.lightTheme, isTrue);
  });

  test('light theme notifies only on change', () {
    final LabSettings lab = LabSettings();
    addTearDown(lab.dispose);
    int lab0 = 0;
    int theme0 = 0;
    lab.addListener(() => lab0++);
    lab.lightThemeListenable.addListener(() => theme0++);

    lab
      ..setLightTheme(false)
      ..setLightTheme(true)
      ..setLightTheme(true);

    expect(lab0, 1);
    expect(theme0, 1);
    expect(lab.lightThemeListenable.value, isTrue);
  });

  test('backdrop painters follow the brightness', () {
    expect(kTodoBackdrop.brightness, Brightness.dark);
    expect(kTodoBackdropLight.brightness, Brightness.light);
    expect(todoBackdropFor(Brightness.dark), same(kTodoBackdrop));
    expect(todoBackdropFor(Brightness.light), same(kTodoBackdropLight));
    expect(kTodoBackdropLight.shouldRepaint(kTodoBackdrop), isTrue);
    expect(kTodoBackdrop.shouldRepaint(const TodoBackdropPainter()), isFalse);
    expect(kTodoBackdropLight.isOpaque, isTrue);
  });

  testWidgets('light theme switch flips the app and the glass appearance', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    BuildContext page() => tester.element(find.text('My Tasks'));

    expect(Theme.of(page()).brightness, Brightness.dark);
    expect(MediaQuery.platformBrightnessOf(page()), Brightness.dark);

    await _openLab(tester);
    await tester.tap(find.byKey(_key('lab-light-theme')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(Theme.of(page()).brightness, Brightness.light);
    expect(MediaQuery.platformBrightnessOf(page()), Brightness.light);
    expect(
      tester.widget<GlassBadge>(find.byKey(_key('lab-badge'))).isVisible,
      isFalse,
    );

    await _closeLab(tester);
  });

  testWidgets('the dark theme keeps dark glass on a light-mode device', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);

    expect(
      MediaQuery.platformBrightnessOf(tester.element(find.text('My Tasks'))),
      Brightness.dark,
    );
  });
}

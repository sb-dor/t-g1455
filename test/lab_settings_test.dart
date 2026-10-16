import 'package:flutter_test/flutter_test.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugPaintGlassSurfaces = false);

  test('defaults have no changes', () {
    final LabSettings lab = LabSettings();
    expect(lab.hasChanges, isFalse);
    expect(lab.tier.tier, GlassTier.full);
    expect(lab.glassRipple, isNull);
    expect(lab.glassHighContrast, isNull);
  });

  test('reduce transparency picks the opaque tier', () {
    final LabSettings lab = LabSettings()..setReduceTransparency(true);
    expect(lab.tier.tier, GlassTier.opaque);
    expect(lab.hasChanges, isTrue);
  });

  test('cheap ceiling picks the cheap tier', () {
    final LabSettings lab = LabSettings()..setCheapCeiling(true);
    expect(lab.tier.tier, GlassTier.cheap);
  });

  test('zero stretch is no drop motion', () {
    final LabSettings lab = LabSettings()..setDropStretch(0);
    expect(lab.dropMotion.isNone, isTrue);
  });

  test('setters notify only on change', () {
    final LabSettings lab = LabSettings();
    int calls = 0;
    lab.addListener(() => calls++);
    lab.setPress(true);
    lab.setFinish(LabFinish.auto);
    expect(calls, 0);
    lab.setPress(false);
    expect(calls, 1);
  });

  test('reset restores every default', () {
    final LabSettings lab = LabSettings()
      ..setFinish(LabFinish.clear)
      ..setReduceTransparency(true)
      ..setCheapCeiling(true)
      ..setRipple(true)
      ..setDropStretch(0.4)
      ..setPress(false)
      ..setAdaptive(false)
      ..setHighContrast(true)
      ..setDebugOutlines(true)
      ..setGlassRows(true);
    expect(lab.hasChanges, isTrue);
    expect(debugPaintGlassSurfaces, isTrue);
    lab.reset();
    expect(lab.hasChanges, isFalse);
    expect(debugPaintGlassSurfaces, isFalse);
    expect(lab.finish, LabFinish.auto);
    expect(lab.dropStretch, 0.12);
  });

  testWidgets('lab changes reach the host', (WidgetTester tester) async {
    final LabSettings lab = LabSettings();
    await pumpApp(tester, lab: lab);
    lab
      ..setRipple(true)
      ..setFinish(LabFinish.frosted);
    await tester.pump();
    await tester.pump();
    final GlassThemeData theme = GlassTheme.of(
      tester.element(find.text('My Tasks')),
    );
    expect(theme.ripple, isNotNull);
    expect(theme.finish.name, GlassFinish.frosted.name);
  });

  testWidgets('debug outlines reassemble a running app', (
    WidgetTester tester,
  ) async {
    final LabSettings lab = LabSettings();
    await pumpApp(tester, lab: lab);
    lab.setDebugOutlines(true);
    await tester.pump();
    await tester.pump();
    expect(debugPaintGlassSurfaces, isTrue);
    expect(find.text('My Tasks'), findsOneWidget);
    lab.reset();
    await tester.pump();
    await tester.pump();
    expect(debugPaintGlassSurfaces, isFalse);
  });
}

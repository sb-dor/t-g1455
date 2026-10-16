// F02: in the light appearance, adaptive glass over a backdrop between luma 54
// (GlassFinish.kRegularSwitchLight) and the black/white contrast midpoint
// (~118) is drawn on regularLight, while GlassBackdropReading.brightness says
// Brightness.dark. The GlassBackdropReading dartdoc example
// (glass_adaptive.dart:201-205) maps `reading?.brightness == Brightness.light`
// to a black icon and anything else to a white one, so it picks a white icon
// for light glass. The "Content on the glass" snippet on foundations/adaptive
// computes the same `overLight` and stops there.
//
// Run on a device or simulator in the LIGHT system appearance:
//   flutter run -t repro/f02_reading_brightness_recipe.dart
//   flutter run -t repro/f02_reading_brightness_recipe.dart --dart-define=LEVEL=40
//
// The page is one flat grey of luma LEVEL (default 70). The bar shows three
// marks: the bar's own label, an icon coloured by that example, and an
// icon coloured by GlassTheme.of(context).legibility().label.
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const int kLevel = int.fromEnvironment('LEVEL', defaultValue: 70);

Color get _page => Color.fromARGB(255, kLevel, kLevel, kLevel);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(const ReproApp());
}

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (BuildContext context, Widget? child) => GlassHost(
      backdrop: _page,
      adaptive: const GlassAdaptive(),
      child: child!,
    ),
    home: const Material(color: Color(0x00000000), child: ReproPage()),
  );
}

class ReproPage extends StatelessWidget {
  const ReproPage({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _page,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // A caption for screenshots, in white at 60% so it shows on the grey
        // page. It is not under the bar: the bar's reading is the flat page
        // colour behind it.
        Center(
          child: Text(
            'page luma $kLevel · system appearance '
            '${MediaQuery.platformBrightnessOf(context).name}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: MediaQuery.paddingOf(context).top + 16,
          child: const GlassBar(child: _Marks()),
        ),
      ],
    ),
  );
}

class _Marks extends StatelessWidget {
  const _Marks();

  @override
  Widget build(BuildContext context) {
    final GlassThemeData theme = GlassTheme.of(context);
    final GlassBackdropReading? reading = theme.reading;
    // `overLight` is the line from foundations/adaptive, "Content on the
    // glass"; mapping it to black/white is the dartdoc example on
    // GlassBackdropReading (glass_adaptive.dart:201-205).
    final bool overLight = reading?.brightness == Brightness.light;
    final Color recipe = overLight
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final Color label = theme.legibility().label;
    debugPrint(
      'F02 level ${reading?.level.toStringAsFixed(1)}'
      ' reading.brightness ${reading?.brightness.name}'
      ' finish ${theme.finish.name}'
      ' label $label recipe $recipe'
      ' appearance ${MediaQuery.platformBrightnessOf(context).name}',
    );
    return Row(
      children: <Widget>[
        const Text('Label'),
        const Spacer(),
        Icon(Icons.star, color: recipe),
        const SizedBox(width: 4),
        const Text('recipe'),
        const SizedBox(width: 16),
        Icon(Icons.star, color: label),
        const SizedBox(width: 4),
        const Text('legibility()'),
      ],
    );
  }
}

// F01: with GlassHost(adaptive:), GlassTabBar adapts (foundations/adaptive
// says the tab bar does not adapt yet), and its bottomAccessory adapts on its
// own, so the two can sit on different branches of .regular.
//
// Run:
//   flutter run -t repro/f01_tab_bar_adaptive.dart
//   flutter run -t repro/f01_tab_bar_adaptive.dart --dart-define=ADAPTIVE=false
//   flutter run -t repro/f01_tab_bar_adaptive.dart --dart-define=GREEN=false
//   flutter run -t repro/f01_tab_bar_adaptive.dart --dart-define=WIDTH=200
//
// The page is one dark colour, with a small bright block under the left end of
// the tab bar (a stand-in for an "on" switch in a list row). The readings are
// printed to the console and shown in the accessory.
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const bool kAdaptive = bool.fromEnvironment('ADAPTIVE', defaultValue: true);
const bool kGreen = bool.fromEnvironment('GREEN', defaultValue: true);
const int kBrightWidth = int.fromEnvironment('WIDTH', defaultValue: 64);

const Color kPage = Color(0xFF1A1D29);
const Color kBright = Color(0xFF34C759);

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
    theme: ThemeData(brightness: Brightness.dark),
    builder: (BuildContext context, Widget? child) => GlassHost(
      backdrop: kPage,
      adaptive: kAdaptive ? const GlassAdaptive() : null,
      child: child!,
    ),
    home: const Material(color: Color(0x00000000), child: ReproPage()),
  );
}

class ReproPage extends StatefulWidget {
  const ReproPage({super.key});

  @override
  State<ReproPage> createState() => _ReproPageState();
}

class _ReproPageState extends State<ReproPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => GlassScaffold(
    body: const _Page(),
    bottomBar: GlassTabBar(
      items: <GlassTabItem>[
        GlassTabItem(
          label: 'One',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              _Reading(
                name: 'tab bar',
                child: Icon(
                  Icons.looks_one,
                  color: look.color,
                  size: look.iconSize,
                ),
              ),
        ),
        const GlassTabItem(label: 'Two', icon: Icons.looks_two),
        const GlassTabItem(label: 'Three', icon: Icons.looks_3),
      ],
      selectedIndex: _tab,
      onSelected: (int index) => setState(() => _tab = index),
      bottomAccessory: const _Reading(name: 'accessory', showText: true),
    ),
  );
}

/// Prints, and optionally shows, what the glass it sits in read.
class _Reading extends StatelessWidget {
  const _Reading({required this.name, this.showText = false, this.child});

  final String name;
  final bool showText;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final GlassThemeData theme = GlassTheme.of(context);
    final GlassBackdropReading? reading = theme.reading;
    final String text =
        '$name: level ${reading?.level.toStringAsFixed(1) ?? '-'}'
        ' ${reading?.brightness.name ?? 'no reading'}'
        ' · adaptive $kAdaptive · bright block $kGreen ($kBrightWidth px)';
    debugPrint('F01 $text');
    return child ?? Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) {
    // A fixed offset from the screen's bottom edge: GlassScaffold adds the
    // bars' extents to the body's MediaQuery padding.
    return ColoredBox(
      color: kPage,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (kGreen)
            Positioned(
              left: 24,
              bottom: 42,
              width: kBrightWidth.toDouble(),
              height: 30,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: kBright,
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),
          Center(
            child: Text(
              'adaptive $kAdaptive · bright block $kGreen',
              style: const TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}

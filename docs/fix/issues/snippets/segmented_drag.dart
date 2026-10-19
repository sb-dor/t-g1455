import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

// Press "One" and drag toward "Two" without letting go: "One" stays black
// while the white capsule under it fades into the glass drop.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(platformBrightness: Brightness.dark),
        child: GlassHost(backdrop: const Color(0xFF1B1E2B), child: child!),
      ),
      home: const Material(color: Color(0xFF1B1E2B), child: Segments()),
    ),
  );
}

class Segments extends StatefulWidget {
  const Segments({super.key});

  @override
  State<Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<Segments> {
  int segment = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: GlassSegmentedControl(
          segments: const <Widget>[Text('One'), Text('Two'), Text('Three')],
          selectedIndex: segment,
          onSelected: (int i) => setState(() => segment = i),
        ),
      ),
    ),
  );
}

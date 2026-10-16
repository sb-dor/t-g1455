// F03: components/switch says "At rest the knob and the track are ordinary
// paint, not glass ... a page with twenty switches costs the glass nothing
// until someone touches one". Twenty resting GlassSwitches are counted by the
// glass ledger and outlined by debugPaintGlassSurfaces.
//
// Run:
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart --dart-define=SWITCHES=0
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart --dart-define=OUTLINES=true
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const int kSwitches = int.fromEnvironment('SWITCHES', defaultValue: 20);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  debugPaintGlassSurfaces = const bool.fromEnvironment('OUTLINES');
  runApp(const ReproApp());
}

class ReproApp extends StatelessWidget {
  const ReproApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark),
    builder: (BuildContext context, Widget? child) => GlassHost(
      backdrop: const Color(0xFF1A1D29),
      child: child!,
    ),
    home: const Scaffold(
      backgroundColor: Color(0xFF1A1D29),
      body: SafeArea(child: ReproPage()),
    ),
  );
}

class ReproPage extends StatefulWidget {
  const ReproPage({super.key});

  @override
  State<ReproPage> createState() => _ReproPageState();
}

class _ReproPageState extends State<ReproPage> {
  final List<bool> _on = List<bool>.generate(kSwitches, (int i) => i.isEven);
  Timer? _timer;
  String _ledger = 'reading…';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _read());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _read() {
    final GlassLoad? load = GlassScope.maybeOf(context)?.read(
      viewSize: MediaQuery.sizeOf(context),
      model: GlassHardware.detect().surfaceCostModel,
    );
    final String text = load == null
        ? 'no ledger'
        : '$kSwitches switches at rest → ${load.surfaceCount} surfaces, '
              '${load.capturedSurfaceCount} captured, '
              '${load.screensOfGlass.toStringAsFixed(3)} screens';
    debugPrint('F03 $text');
    setState(() => _ledger = text);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_ledger, style: const TextStyle(color: Colors.white)),
      ),
      Expanded(
        child: GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            for (int i = 0; i < kSwitches; i++)
              Center(
                child: GlassSwitch(
                  value: _on[i],
                  onChanged: (bool v) => setState(() => _on[i] = v),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

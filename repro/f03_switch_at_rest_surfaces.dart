// F03: GlassLedger.read counts a control's resting drop as captured.
//
// A resting GlassSwitch (or GlassSlider) knob is a GlassSurface at
// materialize 0, by design (glass_controls.dart:17-19, :184-189). The host
// captures nothing for such a surface (glass_host.dart:1131 keeps only
// `readsCapture && presence > 0 && materialize > 0`), but GlassLedger.read
// counts it as captured, because it tests only `readsCapture`
// (glass_ledger.dart:425, :74), which ignores materialize and presence.
//
// This program reads the ledger once a second and shows the result: with
// twenty resting switches, capturedSurfaceCount is 20; the host captures none.
//
// Run:
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart --dart-define=SWITCHES=0
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart --dart-define=SWITCHES=0 --dart-define=SLIDERS=10
//   flutter run -t repro/f03_switch_at_rest_surfaces.dart --dart-define=OUTLINES=true
//
// OUTLINES is context only: debugPaintGlassSurfaces outlines every registered
// surface, and the resting knob is registered on purpose.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const int kSwitches = int.fromEnvironment('SWITCHES', defaultValue: 20);
const int kSliders = int.fromEnvironment('SLIDERS');

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
  final List<double> _level = List<double>.generate(
    kSliders,
    (int i) => 0.2 + 0.6 * (i % 5) / 4,
  );
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
        : '$kSwitches switches + $kSliders sliders at rest\n'
              'surfaceCount ${load.surfaceCount}\n'
              'capturedSurfaceCount ${load.capturedSurfaceCount}'
              '  (the host captures none of these)\n'
              'screensOfGlass ${load.screensOfGlass.toStringAsFixed(3)}';
    debugPrint('F03 ${text.replaceAll('\n', ' | ')}');
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
      if (kSwitches > 0)
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
      if (kSliders > 0)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              for (int i = 0; i < kSliders; i++)
                GlassSlider(
                  value: _level[i],
                  onChanged: (double v) => setState(() => _level[i] = v),
                ),
            ],
          ),
        ),
    ],
  );
}

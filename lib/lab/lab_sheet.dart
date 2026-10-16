import 'dart:async';

import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';

const double _kSheetPadding = 20;

/// Opens the Glass Lab: every [LabSettings] knob, and a live readout of the
/// glass on screen.
Future<void> showLabSheet(BuildContext context, LabSettings lab) =>
    showGlassSheet<void>(
      context: context,
      barrierLabel: 'Close Glass Lab',
      detents: <GlassSheetDetent>[
        GlassSheetDetent.medium,
        GlassSheetDetent.large,
      ],
      builder: (BuildContext context) => _LabSheet(lab: lab),
    );

class _LabSheet extends StatelessWidget {
  const _LabSheet({required this.lab});

  final LabSettings lab;

  @override
  Widget build(BuildContext context) {
    final Color label = GlassTheme.of(context).legibility().label;
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: label),
        child: IconTheme.merge(
          data: IconThemeData(color: label),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _kSheetPadding,
              8,
              _kSheetPadding,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: ListenableBuilder(
              listenable: lab,
              builder: (BuildContext context, Widget? _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Glass Lab',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const _LedgerReadout(),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    switchKey: 'lab-light-theme',
                    label: 'Light theme',
                    value: lab.lightTheme,
                    onChanged: lab.setLightTheme,
                  ),
                  const SizedBox(height: 8),
                  const Text('Finish'),
                  const SizedBox(height: 8),
                  GlassSegmentedControl(
                    key: const ValueKey<String>('lab-finish'),
                    segments: <Widget>[
                      for (final LabFinish finish in LabFinish.values)
                        Text(finish.label),
                    ],
                    selectedIndex: lab.finish.index,
                    onSelected: (int index) =>
                        lab.setFinish(LabFinish.values[index]),
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    switchKey: 'lab-reduce-transparency',
                    label: 'Reduce transparency',
                    value: lab.reduceTransparency,
                    onChanged: lab.setReduceTransparency,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-cheap-ceiling',
                    label: 'Low-end device',
                    value: lab.cheapCeiling,
                    onChanged: lab.setCheapCeiling,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-ripple',
                    label: 'Ripple',
                    value: lab.ripple,
                    onChanged: lab.setRipple,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-press',
                    label: 'Button press swell',
                    value: lab.press,
                    onChanged: lab.setPress,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-adaptive',
                    label: 'Adaptive glass',
                    value: lab.adaptive,
                    onChanged: lab.setAdaptive,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-high-contrast',
                    label: 'High contrast',
                    value: lab.highContrast,
                    onChanged: lab.setHighContrast,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-debug-outlines',
                    label: 'Debug outlines',
                    value: lab.debugOutlines,
                    onChanged: lab.setDebugOutlines,
                  ),
                  _SwitchRow(
                    switchKey: 'lab-glass-rows',
                    label: 'Glass rows',
                    value: lab.glassRows,
                    onChanged: lab.setGlassRows,
                  ),
                  const SizedBox(height: 8),
                  const Text('Drop stretch'),
                  GlassSlider(
                    key: const ValueKey<String>('lab-drop-stretch'),
                    value: lab.dropStretch / LabSettings.maxDropStretch,
                    divisions: 10,
                    semanticLabel: 'Drop stretch',
                    onChanged: (double value) =>
                        lab.setDropStretch(value * LabSettings.maxDropStretch),
                  ),
                  const SizedBox(height: 14),
                  GlassButton(
                    key: const ValueKey<String>('lab-reset'),
                    onPressed: lab.hasChanges ? lab.reset : null,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String switchKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          GlassSwitch(
            key: ValueKey<String>(switchKey),
            value: value,
            onChanged: onChanged,
            semanticLabel: label,
          ),
        ],
      ),
    ),
  );
}

/// One line saying how much glass is on screen, read from the package's
/// ledger once a second.
class _LedgerReadout extends StatefulWidget {
  const _LedgerReadout();

  @override
  State<_LedgerReadout> createState() => _LedgerReadoutState();
}

class _LedgerReadoutState extends State<_LedgerReadout> {
  late final Timer _timer;
  late final GlassSurfaceCostModel _model;

  @override
  void initState() {
    super.initState();
    _model = GlassHardware.detect().surfaceCostModel;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer _) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GlassLoad? load = GlassScope.maybeOf(context)
        ?.read(viewSize: MediaQuery.sizeOf(context), model: _model);
    return Text(
      load == null
          ? 'No ledger'
          : '${load.surfaceCount} surfaces · '
                '${load.capturedSurfaceCount} captured · '
                '${load.screensOfGlass.toStringAsFixed(2)} screens · '
                '${load.verdict.name}',
      key: const ValueKey<String>('lab-ledger'),
    );
  }
}

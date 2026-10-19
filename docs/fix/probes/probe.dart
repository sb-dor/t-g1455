// g1455 bug-hunting probe: one scene per run, set up in code so every
// screenshot is repeatable (no taps from outside the app).
//
//   flutter run -t docs/fix/probes/probe.dart --dart-define=SCENE=controls
//
// Defines:
//   SCENE   controls | menu | popover | alert | stepper | drag | tabs
//   RTL     true to lay the scene out right to left
//   SCALE   text scale factor, e.g. 2.0 (accessibility sizes)
//   LIGHT   true for the light appearance (default dark)
//   ACTIONS number of alert actions (alert scene), default 2
//   AUTO    false to skip the scripted taps (tabs scene) and tap by hand
//   ARABIC  true for Arabic tab labels (tabs scene), as a real RTL app has
//
// Every scene prints "PROBE ..." lines to the console with what it measured.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const String kScene = String.fromEnvironment('SCENE', defaultValue: 'controls');
const bool kRtl = bool.fromEnvironment('RTL');
const bool kLight = bool.fromEnvironment('LIGHT');
const String kScale = String.fromEnvironment('SCALE', defaultValue: '1');
const int kActions = int.fromEnvironment('ACTIONS', defaultValue: 2);
const bool kAuto = bool.fromEnvironment('AUTO', defaultValue: true);
const bool kArabic = bool.fromEnvironment('ARABIC');

double get _scale => double.tryParse(kScale) ?? 1;
Brightness get _brightness => kLight ? Brightness.light : Brightness.dark;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  FlutterError.onError = (FlutterErrorDetails d) {
    debugPrint('PROBE error: ${d.exceptionAsString().split('\n').first}');
    FlutterError.presentError(d);
  };
  runApp(const ProbeApp());
}

class ProbeApp extends StatelessWidget {
  const ProbeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: _brightness),
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        platformBrightness: _brightness,
        textScaler: TextScaler.linear(_scale),
      ),
      child: Directionality(
        textDirection: kRtl ? TextDirection.rtl : TextDirection.ltr,
        child: GlassHost(
          backdrop: kLight ? const Color(0xFFE9E6F2) : const Color(0xFF1B1E2B),
          child: child!,
        ),
      ),
    ),
    home: const Material(type: MaterialType.transparency, child: _Scene()),
  );
}

/// A backdrop with structure, so glass has something to refract.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: kLight
            ? const <Color>[
                Color(0xFFF7F4FF),
                Color(0xFFDCD3FA),
                Color(0xFFCDEDEA),
              ]
            : const <Color>[
                Color(0xFF141726),
                Color(0xFF2E2560),
                Color(0xFF123A44),
              ],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (int i = 0; i < 9; i++)
          Positioned(
            top: 60.0 + i * 90,
            left: i.isEven ? -40 : 120,
            child: Container(
              width: 260,
              height: 26,
              decoration: BoxDecoration(
                color: <Color>[
                  const Color(0xFFFF9F0A),
                  const Color(0xFF30D158),
                  const Color(0xFF0A84FF),
                ][i % 3].withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        child,
      ],
    ),
  );
}

class _Scene extends StatelessWidget {
  const _Scene();

  @override
  Widget build(BuildContext context) => _Backdrop(
    child: switch (kScene) {
      'menu' => const _MenuScene(),
      'popover' => const _PopoverScene(),
      'alert' => const _AlertScene(),
      'stepper' => const _StepperScene(),
      'drag' => const _DragScene(),
      'tabs' => const _TabsScene(),
      _ => const _ControlsScene(),
    },
  );
}

// ---------------------------------------------------------------- controls

class _ControlsScene extends StatefulWidget {
  const _ControlsScene();

  @override
  State<_ControlsScene> createState() => _ControlsSceneState();
}

class _ControlsSceneState extends State<_ControlsScene> {
  bool _on = true;
  double _slider = 0.35;
  double _stepper = 3;
  int _segment = 1;
  int _tab = 0;
  int _page = 1;

  @override
  Widget build(BuildContext context) => GlassScaffold(
    topBar: GlassBar(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          const Icon(Icons.arrow_back_ios_new, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          GlassBadge(count: 7, child: const Icon(Icons.notifications_none)),
        ],
      ),
    ),
    bottomBar: GlassTabBar(
      items: <GlassTabItem>[
        GlassTabItem(
          label: 'Home',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              GlassBadge(
                count: 2,
                child: Icon(
                  Icons.home_outlined,
                  color: look.color,
                  size: look.iconSize,
                ),
              ),
        ),
        const GlassTabItem(label: 'Search', icon: Icons.search),
        const GlassTabItem(
          label: 'Library',
          icon: Icons.library_music_outlined,
        ),
        const GlassTabItem(label: 'Profile', icon: Icons.person_outline),
      ],
      selectedIndex: _tab,
      onSelected: (int i) => setState(() => _tab = i),
    ),
    body: Builder(
      builder: (BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 12,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: <Widget>[
          const GlassSearchBar(placeholder: 'Search settings'),
          const SizedBox(height: 12),
          const GlassTextField(placeholder: 'Display name'),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(child: Text('Notifications')),
                    GlassSwitch(
                      value: _on,
                      onChanged: (bool v) => setState(() => _on = v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: Text('Copies: ${_stepper.round()}')),
                    GlassStepper(
                      value: _stepper,
                      min: 1,
                      max: 10,
                      semanticLabel: 'Copies',
                      onChanged: (double v) => setState(() => _stepper = v),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GlassSlider(
                  value: _slider,
                  onChanged: (double v) => setState(() => _slider = v),
                ),
                const SizedBox(height: 10),
                GlassSegmentedControl(
                  segments: const <Widget>[
                    Text('Day'),
                    Text('Week'),
                    Text('Month'),
                  ],
                  selectedIndex: _segment,
                  onSelected: (int i) => setState(() => _segment = i),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              GlassButton(onPressed: () {}, child: const Text('Cancel')),
              GlassButton(onPressed: () {}, child: const Text('Save changes')),
              GlassButtonGroup(
                items: <GlassToolbarItem>[
                  GlassToolbarItem(
                    icon: const Icon(Icons.share_outlined),
                    label: 'Share',
                    onPressed: () {},
                  ),
                  GlassToolbarItem(
                    icon: const Icon(Icons.delete_outline),
                    label: 'Delete',
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GlassPageControl(
              count: 5,
              currentPage: _page,
              onPageChanged: (int p) => setState(() => _page = p),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------- menus

class _MenuScene extends StatefulWidget {
  const _MenuScene();

  @override
  State<_MenuScene> createState() => _MenuSceneState();
}

class _MenuSceneState extends State<_MenuScene> {
  final GlassMenuController _menu = GlassMenuController();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 600), _menu.open);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: AlignmentDirectional.topEnd,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassMenuAnchor(
          controller: _menu,
          items: <GlassMenuItem>[
            GlassMenuItem(
              label: 'Rename',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {},
            ),
            GlassMenuItem(
              label: 'Move to another folder with a long name',
              icon: const Icon(Icons.folder_open, size: 20),
              onPressed: () {},
            ),
            const GlassMenuItem(
              label: 'Disabled action',
              icon: Icon(Icons.block, size: 20),
            ),
            GlassMenuItem(
              label: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 20),
              isDestructive: true,
              onPressed: () {},
            ),
          ],
          builder: (BuildContext context, GlassMenuController menu) =>
              GlassButton(
                onPressed: menu.open,
                padding: EdgeInsets.zero,
                semanticLabel: 'More',
                child: const Icon(Icons.more_horiz),
              ),
        ),
      ),
    ),
  );
}

class _PopoverScene extends StatefulWidget {
  const _PopoverScene();

  @override
  State<_PopoverScene> createState() => _PopoverSceneState();
}

class _PopoverSceneState extends State<_PopoverScene> {
  final GlassMenuController _popover = GlassMenuController();
  bool _on = true;
  int _segment = 0;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 600), _popover.open);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: AlignmentDirectional.bottomStart,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPopoverAnchor(
          controller: _popover,
          popoverBuilder: (BuildContext context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setLocal) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  GlassSegmentedControl(
                    segments: const <Widget>[Text('All'), Text('Unread')],
                    selectedIndex: _segment,
                    onSelected: (int i) => setLocal(() => _segment = i),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Text('Show archived')),
                      GlassSwitch(
                        value: _on,
                        onChanged: (bool v) => setLocal(() => _on = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          builder: (BuildContext context, GlassMenuController popover) =>
              GlassButton(
                onPressed: popover.open,
                child: const Text('Filters'),
              ),
        ),
      ),
    ),
  );
}

class _AlertScene extends StatefulWidget {
  const _AlertScene();

  @override
  State<_AlertScene> createState() => _AlertSceneState();
}

class _AlertSceneState extends State<_AlertScene> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 600), () {
      showGlassDialog<void>(
        context: context,
        builder: (BuildContext context) => GlassAlert(
          title: const Text(
            'Delete “Quarterly planning notes and attachments”?',
          ),
          message: const Text(
            'This removes the note from all of your devices. It cannot be undone.',
          ),
          actions: <GlassAlertAction>[
            GlassAlertAction(
              label: 'Cancel',
              isDefault: true,
              onPressed: () {},
            ),
            if (kActions >= 3)
              GlassAlertAction(label: 'Move to Archive', onPressed: () {}),
            GlassAlertAction(
              label: 'Delete',
              isDestructive: true,
              onPressed: () {},
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

// ---------------------------------------------------------------- gestures

/// Sends a touch down at [at], optionally moves it, and lifts it after [hold].
Future<void> _touch(
  Offset at, {
  Duration hold = Duration.zero,
  Offset? moveTo,
  int steps = 12,
}) async {
  const int pointer = 4242;
  final GestureBinding binding = GestureBinding.instance;
  binding.handlePointerEvent(PointerDownEvent(pointer: pointer, position: at));
  Offset p = at;
  if (moveTo != null) {
    final Duration tick = Duration(microseconds: hold.inMicroseconds ~/ steps);
    for (int i = 1; i <= steps; i++) {
      await Future<void>.delayed(tick);
      final Offset next = Offset.lerp(at, moveTo, i / steps)!;
      binding.handlePointerEvent(
        PointerMoveEvent(pointer: pointer, position: next, delta: next - p),
      );
      p = next;
    }
  } else {
    await Future<void>.delayed(hold);
  }
  binding.handlePointerEvent(PointerUpEvent(pointer: pointer, position: p));
}

Rect _rectOf(GlobalKey key) {
  final RenderBox box = key.currentContext!.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

class _StepperScene extends StatefulWidget {
  const _StepperScene();

  @override
  State<_StepperScene> createState() => _StepperSceneState();
}

class _StepperSceneState extends State<_StepperScene> {
  final GlobalKey _key = GlobalKey();
  double _value = 0;
  final Stopwatch _clock = Stopwatch();
  final List<String> _log = <String>[];

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () async {
      final Rect r = _rectOf(_key);
      // The plus half: trailing in LTR, leading in RTL.
      final Offset plus = kRtl
          ? Offset(r.left + r.width * 0.25, r.center.dy)
          : Offset(r.right - r.width * 0.25, r.center.dy);
      _clock.start();
      await _touch(plus, hold: const Duration(milliseconds: 3000));
      _clock.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      debugPrint(
        'PROBE stepper held 3000 ms → value ${_value.round()} '
        '(expected 1 + floor((3000-500)/100) = 26 at the documented 500 ms delay and 100 ms interval)',
      );
      debugPrint('PROBE stepper steps at ms: ${_log.join(', ')}');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'value ${_value.round()}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GlassStepper(
              key: _key,
              value: _value,
              min: 0,
              max: 100,
              semanticLabel: 'Count',
              onChanged: (double v) {
                _log.add('${_clock.elapsedMilliseconds}');
                setState(() => _value = v);
              },
            ),
            const SizedBox(height: 12),
            Text(
              _log.isEmpty ? 'holding plus for 3 s…' : 'steps: ${_log.length}',
            ),
          ],
        ),
      ),
    ),
  );
}

class _DragScene extends StatefulWidget {
  const _DragScene();

  @override
  State<_DragScene> createState() => _DragSceneState();
}

class _DragSceneState extends State<_DragScene> {
  final GlobalKey _segKey = GlobalKey();
  final GlobalKey _sliderKey = GlobalKey();
  final GlobalKey _switchKey = GlobalKey();
  int _segment = 0;
  double _slider = 0.1;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    // AUTO (default): drag from "One" toward "Two" and hold, over and over,
    // starting from "One" selected each time. AUTO=false: drag it yourself.
    if (kAuto) Timer(const Duration(milliseconds: 1500), _loop);
  }

  Future<void> _loop() async {
    while (mounted) {
      setState(() => _segment = 0);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final Rect s = _rectOf(_segKey);
      await _touch(
        Offset(s.left + s.width / 6, s.center.dy),
        moveTo: Offset(s.left + s.width * 0.55, s.center.dy),
        hold: const Duration(milliseconds: 4000),
        steps: 30,
      );
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GlassSegmentedControl(
              key: _segKey,
              segments: const <Widget>[Text('One'), Text('Two'), Text('Three')],
              selectedIndex: _segment,
              onSelected: (int i) => setState(() => _segment = i),
            ),
            const SizedBox(height: 16),
            GlassSlider(
              key: _sliderKey,
              value: _slider,
              onChanged: (double v) => setState(() => _slider = v),
            ),
            const SizedBox(height: 16),
            GlassSwitch(
              key: _switchKey,
              value: _on,
              onChanged: (bool v) => setState(() => _on = v),
            ),
            const SizedBox(height: 20),
            Text(
              kAuto
                  ? 'Watch "One" while the glass drop moves toward "Two".'
                  : 'Press and drag the selection in the top control.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Taps the centre of each tab as it appears on screen (found by its label)
/// and logs which index the bar reports. Under RTL the visual order flips.
class _TabsScene extends StatefulWidget {
  const _TabsScene();

  @override
  State<_TabsScene> createState() => _TabsSceneState();
}

class _TabsSceneState extends State<_TabsScene> {
  static const List<String> _labels = kArabic
      ? <String>['الرئيسية', 'بحث', 'المكتبة', 'الملف']
      : <String>['Home', 'Search', 'Library', 'Profile'];
  final List<GlobalKey> _keys = List<GlobalKey>.generate(4, (_) => GlobalKey());
  int _tab = 0;
  String? _tapped;
  Offset? _finger;

  @override
  void initState() {
    super.initState();
    if (!kAuto) return;
    Timer(const Duration(milliseconds: 1500), () async {
      for (final int i in <int>[1, 2, 3, 0, 1]) {
        final Rect r = _rectOf(_keys[i]);
        // Show where the finger lands, then tap there.
        setState(() {
          _tapped = _labels[i];
          _finger = r.center;
        });
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await _touch(r.center, hold: const Duration(milliseconds: 80));
        await Future<void>.delayed(const Duration(milliseconds: 250));
        setState(() => _finger = null);
        debugPrint(
          'PROBE tap on "${_labels[i]}" (x ${r.center.dx.round()}) → selected "${_labels[_tab]}"',
        );
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    });
  }

  String get _status {
    if (!kAuto) {
      return '${kRtl ? 'Right to left' : 'Left to right'}\n\nTap a tab below.\n'
          'The bar selected:\n${_labels[_tab]}';
    }
    if (_tapped == null) return 'tapping each tab…';
    return 'tapped: $_tapped\nbar selected: ${_labels[_tab]}';
  }

  @override
  Widget build(BuildContext context) {
    final bool wrong = kAuto && _tapped != null && _tapped != _labels[_tab];
    return Stack(
      children: <Widget>[
        GlassScaffold(
          body: Center(
            child: Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: wrong ? const Color(0xFFFF6B6B) : null,
              ),
            ),
          ),
          bottomBar: GlassTabBar(
            items: <GlassTabItem>[
              for (int i = 0; i < 4; i++)
                GlassTabItem(
                  label: _labels[i],
                  icon: const <IconData>[
                    Icons.home_outlined,
                    Icons.search,
                    Icons.library_music_outlined,
                    Icons.person_outline,
                  ][i],
                  labelBuilder: (BuildContext context, GlassTabItemLook look) =>
                      Text(_labels[i], key: _keys[i], style: look.labelStyle),
                ),
            ],
            selectedIndex: _tab,
            onSelected: (int i) => setState(() => _tab = i),
          ),
        ),
        if (_finger != null)
          Positioned(
            left: _finger!.dx - 22,
            top: _finger!.dy - 22,
            child: IgnorePointer(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x66FFD60A),
                  border: Border.all(color: const Color(0xFFFFD60A), width: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Candidate F05: the documented GlassBadge-on-a-tab recipe puts the badge's
// centre on the icon's top trailing corner. When the tab bar is wide enough to
// lay icon and label side by side (GlassTabItemLook.inline), the badge covers
// the start of the label. Two-digit counts make it worse.
//
//   flutter run -t repro/candidates/f05_badge_inline_overlap.dart
//   flutter run -t repro/candidates/f05_badge_inline_overlap.dart --dart-define=FIX=true
//
// FIX=true nudges the badge with `offset` when `look.inline` is true.
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const bool kFix = bool.fromEnvironment('FIX');

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
      backdrop: const Color(0xFF1A1D29),
      child: child!,
    ),
    home: const Material(color: Color(0xFF1A1D29), child: ReproPage()),
  );
}

class ReproPage extends StatefulWidget {
  const ReproPage({super.key});

  @override
  State<ReproPage> createState() => _ReproPageState();
}

class _ReproPageState extends State<ReproPage> {
  int _tab = 0;

  Widget _badged(GlassTabItemLook look, int count, IconData icon) => GlassBadge(
    count: count,
    offset: kFix && look.inline ? const Offset(-10, 2) : Offset.zero,
    child: Icon(icon, color: look.color, size: look.iconSize),
  );

  @override
  Widget build(BuildContext context) => GlassScaffold(
    body: Center(
      child: Text(
        'badge fix ${kFix ? 'on' : 'off'}',
        style: const TextStyle(color: Colors.white54),
      ),
    ),
    bottomBar: GlassTabBar(
      items: <GlassTabItem>[
        GlassTabItem(
          label: 'Inbox',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              _badged(look, 3, Icons.inbox),
        ),
        GlassTabItem(
          label: 'Open',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              _badged(look, 12, Icons.radio_button_unchecked),
        ),
        GlassTabItem(
          label: 'Done',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              _badged(look, 128, Icons.task_alt),
        ),
      ],
      selectedIndex: _tab,
      onSelected: (int i) => setState(() => _tab = i),
    ),
  );
}

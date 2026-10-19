import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

// The same controls at 2x text (an iOS "Larger Text" size). Set the scale to 1
// to compare.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(2)),
        child: GlassHost(child: child!),
      ),
      home: const Material(color: Color(0xFF1B1E2B), child: Controls()),
    ),
  );
}

class Controls extends StatefulWidget {
  const Controls({super.key});

  @override
  State<Controls> createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  int tab = 0;
  int segment = 1;

  @override
  Widget build(BuildContext context) => GlassScaffold(
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        16,
      ),
      children: <Widget>[
        const GlassSearchBar(placeholder: 'Search settings'),
        const SizedBox(height: 12),
        const GlassTextField(placeholder: 'Display name'),
        const SizedBox(height: 12),
        GlassSegmentedControl(
          segments: const <Widget>[Text('Day'), Text('Week'), Text('Month')],
          selectedIndex: segment,
          onSelected: (int i) => setState(() => segment = i),
        ),
      ],
    ),
    bottomBar: GlassTabBar(
      items: const <GlassTabItem>[
        GlassTabItem(label: 'Home', icon: Icons.home_outlined),
        GlassTabItem(label: 'Search', icon: Icons.search),
        GlassTabItem(label: 'Library', icon: Icons.library_music_outlined),
        GlassTabItem(label: 'Profile', icon: Icons.person_outline),
      ],
      selectedIndex: tab,
      onSelected: (int i) => setState(() => tab = i),
    ),
  );
}

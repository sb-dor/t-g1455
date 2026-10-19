import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

// Tap any tab: under right-to-left the bar selects the tab at the mirrored
// position. Change TextDirection.rtl to TextDirection.ltr and every tap is right.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: TextDirection.rtl,
        child: GlassHost(child: child!),
      ),
      home: const Material(color: Color(0xFF1B1E2B), child: Tabs()),
    ),
  );
}

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  static const List<String> labels = <String>[
    'الرئيسية',
    'بحث',
    'المكتبة',
    'الملف',
  ];
  int tab = 0;

  @override
  Widget build(BuildContext context) => GlassScaffold(
    body: Center(
      child: Text(
        'selected: ${labels[tab]}',
        style: const TextStyle(fontSize: 24),
      ),
    ),
    bottomBar: GlassTabBar(
      items: const <GlassTabItem>[
        GlassTabItem(label: 'الرئيسية', icon: Icons.home_outlined),
        GlassTabItem(label: 'بحث', icon: Icons.search),
        GlassTabItem(label: 'المكتبة', icon: Icons.library_music_outlined),
        GlassTabItem(label: 'الملف', icon: Icons.person_outline),
      ],
      selectedIndex: tab,
      onSelected: (int i) => setState(() => tab = i),
    ),
  );
}

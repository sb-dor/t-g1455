# GlassTabBar under right-to-left: a tap selects the mirrored tab, and the selection pill is drawn on the mirrored side

## Summary

Under `TextDirection.rtl` (Arabic, Hebrew, Persian, Urdu…) `GlassTabBar` lays its tabs out mirrored, but maps touches and places its resting pill as if the layout were left to right. Every tap selects the tab at the opposite position, so an RTL app navigates to the wrong screen on every tap.

**Video** (Arabic labels; the yellow dot is where the finger lands, the red text is what the bar selected):

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/media/rtl-arabic-taps.gif" alt="RTL tab bar with Arabic labels: each tap selects the mirrored tab" width="420">

**Left: LTR, every tap correct. Right: RTL with Arabic labels, after tapping بحث (Search) the bar selected المكتبة (Library).**

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/shots/0.3.0/rtl-arabic-vs-ltr.png" alt="LTR vs RTL tab bars after the same taps" width="600">

Tapping the centre of each visible tab label (found on screen, then a real pointer down/up):

| Tapped | LTR selects | RTL selects |
|---|---|---|
| Home / الرئيسية | Home | **Profile / الملف** |
| Search / بحث | Search | **Library / المكتبة** |
| Library / المكتبة | Library | **Search / بحث** |
| Profile / الملف | Profile | **Home / الرئيسية** |

Even at rest, the resting pill sits behind the wrong tab: the selected tab (blue, rightmost) has no pill, and the leftmost tab has it.

## Environment

- g1455 **0.3.0** (also 0.2.0), Flutter 3.47.1 stable
- iPhone 17 Pro simulator, iOS 26.5, Impeller (Metal)
- Checked against `master` on 2026-10-19: the code below is unchanged there.

## Steps to reproduce

1. Wrap the app in `Directionality(textDirection: TextDirection.rtl)` (what an Arabic locale gives).
2. Tap any tab.

## Expected behaviour

The tapped tab is selected and the pill sits under it, as in left-to-right.

## Actual behaviour

The tab at the mirrored position is selected, and the pill is drawn at the mirrored position of the selected tab.

## Cause

In `lib/src/surface/glass_tab_bar.dart` (0.3.0):

- The items are laid out in a plain `Row` (line 1081), which mirrors under RTL.
- Touches are mapped with `g.indexAt(e.localPosition.dx, widget.items.length)` (lines 728 and 748), counting from the left.
- The resting pill is placed at `left: g.centre(_at.value) - g.pill.width / 2` (line 1060), also from the left.

The collapse code in the same file already handles `rtl` (lines 802 and 970). `GlassSegmentedControl` solves the same problem with `_visual(int i)` (`glass_segmented_control.dart` line 255, used at 342), which is probably the pattern to reuse here.

## Minimal code

<details>
<summary>rtl_tab_bar.dart</summary>

```dart
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
```

</details>

# Large accessibility text clips the tab bar, segmented control and fields (no text scaling support)

## Summary

With a large text size (iOS Settings › Accessibility › Display & Text Size › Larger Text, which Flutter passes on as `MediaQuery.textScaler`), several g1455 controls keep fixed sizes and clip or overlap their text. There is no `textScaler` handling in `lib/` (0.3.0).

**Tab bar, 1× vs 2× text.** Labels are cut ("Searc", "Libra", "Profil") and icons run into the next label:

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/shots/0.3.0/text-scale-tabbar.png" alt="Tab bar at 1x and 2x text" width="800">

**The whole screen, 1× vs 2×:**

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/shots/0.3.0/text-scale-pair.png" alt="Controls at 1x and 2x text" width="600">

**What clips at 2×:**

- **`GlassTabBar`:** labels truncate mid-word, icons collide with the neighbouring label, the badge covers the icon.
- **`GlassSegmentedControl`:** the capsule keeps its height, so descenders are cut ("Day").
- **`GlassSearchBar` / `GlassTextField`:** fixed at `kGlassFieldHeight` (44, `glass_text_field.dart` line 31), so large text sits tight against the bottom edge.
- **`GlassMenuAnchor`** (minor): rows lose their spacing, icons stay small next to large text, and long labels cut to one line ("Disabled action" → "Disable…") where iOS menus wrap.

**What copes:** `GlassBar`, `GlassButton` (grows), `GlassStepper`, `GlassPageControl`, `GlassAlert` (grows and wraps).

## Environment

- g1455 **0.3.0** (also 0.2.0), Flutter 3.47.1 stable
- iPhone 17 Pro simulator, iOS 26.5, Impeller (Metal)
- Checked against `master` on 2026-10-19: the code below is unchanged there.

## Steps to reproduce

Run the code below (2× text), or set a larger text size on the device.

## Expected behaviour

Text stays whole and readable at accessibility sizes: either the controls grow with the text, or they clamp the scale where iOS does. UIKit caps tab bar labels and shows the large content viewer on long-press instead.

## Actual behaviour

Labels are clipped, truncated or overlapping, as above.

## Possible directions

This is a design choice, so only options:

- clamp the text scale inside the tab bar and segmented control, as UIKit does for tab bars;
- let the fields and the segmented control grow with the text height;
- at large sizes, switch the tab bar to a stacked or icon-only layout.

## Minimal code

<details>
<summary>text_scale.dart</summary>

```dart
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
```

</details>

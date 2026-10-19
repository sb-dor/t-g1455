# Sheet grabber is nearly invisible on dark glass: it always uses the light-appearance grey `0x4D3C3C43`

## Summary

The grabber that `showGlassSheet` draws has one fixed colour, `Color(0x4D3C3C43)` (`glass_modal.dart`, line 856). That is the same value as `kGlassDisabledDarkLabel`, iOS's `tertiaryLabel` for the light appearance: a dark grey at 30%. On a dark sheet (`regularDark`) it is dark on dark and practically disappears.

**Grabber, 3× zoom.** Left: today. Right: the same capsule in `0x4DEBEBF5`.

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/fd4e2aced1952ee2f6a6a5c7cd8f1438e9c01576/docs/candidates/f06-zoom-pair.png" alt="Grabber close-up: today (left) is barely visible, the dark-appearance grey (right) is clear" width="900">

**Whole screen.** Left: today. Right: with the dark-appearance grey.

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/fd4e2aced1952ee2f6a6a5c7cd8f1438e9c01576/docs/candidates/f06-pair-full.png" alt="Dark sheet at the bottom of the screen, today vs with the dark-appearance grabber" width="560">

Measured on the simulator screenshots at the grabber's centre row (sRGB, WCAG contrast ratio):

| | Grabber | Sheet behind it | Contrast |
|---|---|---|---|
| Today, `0x4D3C3C43` | `#35353B` | `#29292F` | **1.18 : 1** |
| `0x4DEBEBF5` | `#707076` | `#29292F` | **2.93 : 1** |

## Environment

- g1455 0.2.0, Flutter 3.47.1 stable
- iPhone 17 Pro simulator, iOS 26.5, Impeller (Metal), dark appearance

## Steps to reproduce

1. Open a sheet with `showGlassSheet` while the glass is on the dark branch (dark appearance, dark backdrop).
2. Look at the grabber at the top of the sheet.

## Expected behaviour

The grabber is visible on a dark sheet, as on iOS, where it is `tertiaryLabel` in each appearance: `rgba(60, 60, 67, 0.3)` in light and `rgba(235, 235, 245, 0.3)` in dark.

## Actual behaviour

The grabber stays `rgba(60, 60, 67, 0.3)` on every sheet, so on dark glass it reads at 1.18 : 1 against the sheet.

## Suggested fix

The package already defines both colours:

```dart
const Color kGlassDisabledDarkLabel = Color(0x4D3C3C43);  // glass_components.dart:79
const Color kGlassDisabledLightLabel = Color(0x4DEBEBF5); // glass_components.dart:87
```

The grabber could take `kGlassDisabledLightLabel` when the sheet is on the dark branch (its label colour is white) and `kGlassDisabledDarkLabel` otherwise, the same black-or-white choice `GlassThemeData.legibility()` makes for labels on glass.

## Minimal code

The repro opens a sheet on launch. It sets `platformBrightness` to dark above the host to stand in for a dark-mode phone. `--dart-define=FIX=true` hides the package grabber and draws the same 36×5 capsule in `0x4DEBEBF5`, which is the right-hand screenshot.

<details>
<summary>f06_sheet_grabber_dark.dart</summary>

```dart
// Candidate F06: the sheet's grabber is painted in a fixed colour,
// Color(0x4D3C3C43) (glass_modal.dart, `_SheetPage`), which is iOS's grabber
// grey for the LIGHT appearance. On a dark sheet (regularDark) it is dark grey
// on dark glass and nearly disappears. iOS draws a light grey grabber on dark
// sheets.
//
//   flutter run -t repro/candidates/f06_sheet_grabber_dark.dart
//   flutter run -t repro/candidates/f06_sheet_grabber_dark.dart --dart-define=FIX=true
//
// FIX=true hides the package grabber and draws the same 36x5 capsule in
// Color(0x4DEBEBF5) (iOS's dark-appearance grabber grey), at the same margins.
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
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.dark),
      child: GlassHost(backdrop: const Color(0xFF1A1D29), child: child!),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showGlassSheet<void>(
        context: context,
        showGrabber: !kFix,
        builder: (BuildContext context) => const _SheetBody(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
    children: <Widget>[
      for (int i = 1; i <= 12; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D3A),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
    ],
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (kFix)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 5, bottom: 4),
              width: 36,
              height: 5,
              decoration: const ShapeDecoration(
                shape: StadiumBorder(),
                color: Color(0x4DEBEBF5),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Text(
            'Sheet · grabber fix ${kFix ? 'on' : 'off'}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: GlassTheme.of(context).legibility().label,
            ),
          ),
        ),
      ],
    ),
  );
}
```

</details>

# Docs: an app with its own theme must declare the glass appearance (a dark app on a light-mode phone gets light glass)

## Summary

The docs say `.regular` picks its branch from the backdrop and the platform's appearance (the GlassHost, Finishes and Adaptive pages). What they don't spell out is what that means for an app whose theme does not follow the phone.

A dark-themed app running on a phone in the **light** appearance gets light glass: near-white bars over its dark content. In the light appearance `.regular` switches to `regularLight` above luma 54 (`kRegularSwitchLight`, `glass_finish.dart:368`), and an ordinary dark grey page is above that. The app has to override the appearance above the `GlassHost` itself. ["What the app declares"](https://g1455.plugfox.dev/start/declarations) lists the backdrop, reduce transparency, contrast and thermal state, but not this.

**A dark-themed app on a light-mode phone.** Left: no override, bars are light. Right: `platformBrightness` overridden to dark above the host, bars are dark.

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/fd4e2aced1952ee2f6a6a5c7cd8f1438e9c01576/docs/candidates/f04-pair.png" alt="Dark-themed app: light glass bars without the override (left), dark glass bars with it (right)" width="560">

## Environment

- g1455 0.2.0, Flutter 3.47.1 stable
- iPhone 17 Pro simulator, iOS 26.5, **light** appearance, Impeller (Metal)

## What an app has to do today

```dart
MaterialApp(
  themeMode: ThemeMode.dark,
  builder: (context, child) => MediaQuery(
    // The glass follows the app's theme, not the phone's.
    data: MediaQuery.of(context).copyWith(platformBrightness: Brightness.dark),
    child: GlassHost(adaptive: const GlassAdaptive(), child: child!),
  ),
  // ...
)
```

Naming a finish (`GlassHost(finish: GlassFinish.regularDark)`) also gives dark glass, but then adaptive glass no longer moves the branch, as the adaptive guide's precedence says. So the override is the option that keeps adaptive working, and an app with a user-selectable theme needs it whenever its theme and the phone's appearance differ.

## Suggestion

Either of these would save the next app from finding this in the source:

- a short section in "What the app declares", with the override above, and a pointer to it from `GlassHost.finish`; or
- a `GlassHost(appearance:)` parameter, so an app with its own theme declares the appearance the way it declares `backdrop`.

## Minimal code

Run it with the device in the light appearance. `--dart-define=FIX=true` adds the override, which is the right-hand screenshot.

<details>
<summary>f04_dark_app_light_phone.dart</summary>

```dart
// Candidate F04 (docs): a dark-themed app on a phone in the LIGHT appearance
// gets light glass over dark content, because g1455 picks the `.regular`
// branch from MediaQuery.platformBrightness (light: switch at luma 54), not
// from the app's theme.
//
//   flutter run -t repro/candidates/f04_dark_app_light_phone.dart
//   flutter run -t repro/candidates/f04_dark_app_light_phone.dart --dart-define=FIX=true
//
// FIX=true overrides platformBrightness to dark above the GlassHost, which is
// what an app with a fixed dark theme has to do today. Run with the device in
// the light appearance.
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

const bool kFix = bool.fromEnvironment('FIX');
const Color kPage = Color(0xFF41414A); // luma ~65: a dark grey page

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
    themeMode: ThemeMode.dark,
    darkTheme: ThemeData(brightness: Brightness.dark),
    builder: (BuildContext context, Widget? child) {
      final Widget host = GlassHost(
        backdrop: kPage,
        adaptive: const GlassAdaptive(),
        child: child!,
      );
      return kFix
          ? MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(platformBrightness: Brightness.dark),
              child: host,
            )
          : host;
    },
    home: const Material(color: kPage, child: ReproPage()),
  );
}

class ReproPage extends StatelessWidget {
  const ReproPage({super.key});

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ListView(
          padding: EdgeInsets.fromLTRB(16, pad.top + 90, 16, 120),
          children: <Widget>[
            for (int i = 1; i <= 14; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34343C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Row $i',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          left: 16,
          right: 16,
          top: pad.top + 12,
          child: const GlassBar(child: Text('Dark-themed app')),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: pad.bottom + 12,
          child: GlassBar(
            child: Text(
              'phone: ${MediaQuery.platformBrightnessOf(context).name}'
              ' · fix ${kFix ? 'on' : 'off'}',
            ),
          ),
        ),
      ],
    );
  }
}
```

</details>

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

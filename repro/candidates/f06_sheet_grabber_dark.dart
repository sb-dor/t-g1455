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

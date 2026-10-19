# GlassSegmentedControl: while dragging, the starting segment's label stays black on dark glass (1.7 : 1)

## Summary

While a finger holds and drags the selection, the white capsule under the selected segment fades as it lifts into the glass drop. The label on it keeps its "on the white capsule" ink, black, so on a dark control it is black on dark grey for the whole drag.

**Video** (dark appearance; the drag repeats from "One" toward "Two"):

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/media/segmented-drag-dark.gif" alt="Segmented control drag: One turns black on the dark track" width="520">

**Frames: at rest → press → dragging → next press.** "One" is black on the white capsule at rest (correct), then stays black once the capsule is gone:

<img src="https://raw.githubusercontent.com/sb-dor/t-g1455/b21d4da7fb1c7ec2cf31a919c287dab89eea46f0/docs/fix/media/segmented-drag-sequence.png" alt="Four frames of the drag" width="520">

Measured on the 0.3.0 recording (sRGB, WCAG contrast ratio):

| Moment | Text | Behind it | Contrast |
|---|---|---|---|
| Dragging, "One" on the track | `#000000` | `#333441` | **1.72 : 1** |
| Pressed, "One" under the drop | `#444447` | `#696871` | **1.75 : 1** |
| Light appearance, label under the drop (measured on 0.2.0, same code) | `#474747` | `#EFEFF3` | 8.11 : 1 |

WCAG asks for 4.5 : 1 for text. Only the dark appearance is affected.

## Environment

- g1455 **0.3.0** (also 0.2.0), Flutter 3.47.1 stable
- iPhone 17 Pro simulator, iOS 26.5, Impeller (Metal)
- Checked against `master` on 2026-10-19: the code below is unchanged there.

## Steps to reproduce

1. Dark appearance (or a dark backdrop).
2. Press the selected segment and drag toward another one without letting go.

## Expected behaviour

The label of the segment the drag left reads like the other labels (white on dark glass) once its white capsule has faded.

## Actual behaviour

It stays black until the finger lifts.

## Cause

In `lib/src/surface/glass_segmented_control.dart` (0.3.0), the selected segment's label goes through `_onThumb` (line 530), which picks black ink for the white capsule (line 543). The capsule fades with the lift (`_fade() => 1 - lift`, line 669), but nothing moves the ink with it.

## Suggested fix

Blend the selected label's ink toward the ambient label colour as the drop lifts, for example `Color.lerp(ink, ambient, lift)`, with the same `lift` value that fades the capsule.

## Minimal code

<details>
<summary>segmented_drag.dart</summary>

```dart
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

// Press "One" and drag toward "Two" without letting go: "One" stays black
// while the white capsule under it fades into the glass drop.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(platformBrightness: Brightness.dark),
        child: GlassHost(backdrop: const Color(0xFF1B1E2B), child: child!),
      ),
      home: const Material(color: Color(0xFF1B1E2B), child: Segments()),
    ),
  );
}

class Segments extends StatefulWidget {
  const Segments({super.key});

  @override
  State<Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<Segments> {
  int segment = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: GlassSegmentedControl(
          segments: const <Widget>[Text('One'), Text('Two'), Text('Three')],
          selectedIndex: segment,
          onSelected: (int i) => setState(() => segment = i),
        ),
      ),
    ),
  );
}
```

</details>

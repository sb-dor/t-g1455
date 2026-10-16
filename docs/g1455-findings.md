# g1455 findings log

## Environment

- g1455 0.2.0 (pub.dev, resolved in `pubspec.lock`)
- Flutter 3.47.1 stable, Dart 3.13
- iOS Simulator: iPhone 17 Pro, iOS 26.5, **light** system appearance (Impeller, Metal)
- Host: macOS 26.6.2, Xcode 26.6
- App: this repo, branch `g1455-todo-coverage`, debug build

## How an entry moves

suspected → (checked against `start/common-errors` and the 27 rules) →
**confirmed** (repro in `repro/`, draft in `docs/issues/`) or **not a bug**
(reason recorded; our code fixed if it was misuse) → **reported #N** (filed by
the user).

## Tools in this repo

- `repro/f0N_*.dart`: one standalone `main()` per confirmed finding, using
  only Flutter and g1455: `flutter run -t repro/<file>.dart`.
- `repro/sim_pass.dart`: the todo app with seeded tasks and Lab settings preset
  from dart-defines (`FINISH`, `REDUCE`, `CHEAP`, `ADAPTIVE`, `CONTRAST`,
  `ROWS`, `OUTLINES`, `RIPPLE`, `TASKS`), for screenshotting a state without
  driving it by touch.

## Findings

### F01: `GlassTabBar` and its `bottomAccessory` adapt, though the docs say the tab bar does not

- Component: `GlassTabBar`, `GlassAdaptive`
- Status: confirmed (docs mismatch, plus a visual split between bar and accessory)
- Steps: `GlassHost(adaptive: const GlassAdaptive())`, light system appearance,
  a `GlassTabBar` with `bottomAccessory` over a dark page with a bright patch
  under the bar only.
- Expected: per `foundations/adaptive` ("the tab bar and the segmented control
  do not adapt yet"), the tab bar keeps the declared branch.
- Actual: the tab bar and the accessory are each a `GlassBar`
  (`glass_tab_bar.dart:853` and `:954`), so each takes its own reading and its
  own branch. The bar read 70.9 (≥ `kRegularSwitchLight` 54) and went
  `regularLight`; the accessory read 29.2 and stayed `regularDark`, directly
  above it. In the app this happened over an ordinary list, with the bar at
  64.9 and the accessory at 37.9.
- Screenshots: `docs/findings/F01-repro-tab-bar-light-accessory-dark.png`,
  `docs/findings/F01-app-tab-bar-light-accessory-dark.png`,
  `docs/findings/F01-app-adaptive-off.png` (same state, adaptive off: both dark)
- Repro: `repro/f01_tab_bar_adaptive.dart --dart-define=WIDTH=200`
- Notes: the branch switch at 54 in the light appearance is by design
  (`GlassFinish.kRegularSwitchLight`). The report is the docs statement and the
  question of whether bar and accessory should share one reading.

### F02: `GlassBackdropReading.brightness` disagrees with the branch drawn; the docs' "Content on the glass" recipe picks white on light glass

- Component: `GlassBackdropReading`, `GlassAdaptive`, docs `foundations/adaptive`
- Status: confirmed (docs / API ergonomics)
- Steps: adaptive on, light system appearance, a `GlassBar` over a flat grey of
  luma 70. Colour an icon with the documented recipe
  `overLight = reading?.brightness == Brightness.light`.
- Expected: the recipe gives an icon that reads on the glass.
- Actual: `reading.level` 70, `reading.brightness` `dark` (black/white contrast
  against the *backdrop*), while the branch drawn is `regularLight` (level ≥ 54).
  The recipe paints a white icon on light glass; `GlassTheme.of(context)
  .legibility().label` gives black. Any backdrop between 54 and ~118 in the
  light appearance is affected (and the mirror range below 222 in the dark one).
- Screenshot: `docs/findings/F02-recipe-white-on-light-glass.png`
- Repro: `repro/f02_reading_brightness_recipe.dart`
- Notes: the docs do say "the branch the glass is on is
  `GlassTheme.of(context).finish`", but the recipe is the code people copy.

### F03: a resting `GlassSwitch` registers a captured glass surface, though the docs say it is ordinary paint

- Component: `GlassSwitch`, `GlassLedger`
- Status: confirmed (docs vs behaviour, cost)
- Steps: twenty `GlassSwitch`es at rest under a `GlassHost`; read the ledger;
  set `debugPaintGlassSurfaces = true`.
- Expected: per `components/switch`, "At rest the knob and the track are
  ordinary paint, not glass … a page with twenty switches costs the glass
  nothing until someone touches one."
- Actual: the ledger reports `20 surfaces, 20 captured`
  (0 switches → `0 surfaces, 0 captured`), and every resting knob is outlined
  by `debugPaintGlassSurfaces` ("outlines every registered surface").
- Screenshot: `docs/findings/F03-twenty-resting-switches-outlined.png`
- Repro: `repro/f03_switch_at_rest_surfaces.dart`
  (`--dart-define=SWITCHES=0`, `--dart-define=OUTLINES=true`)
- Notes: either the resting knob is a registered surface that should not be,
  or the ledger counts surfaces that draw nothing. Either way the docs and the
  ledger disagree.

## Not bugs (resolved)

- **M1, our misuse:** the progress lens and the row switches sit under the
  body's `GlassBackdrop.painter`, so their glass samples the page declaration
  and does not refract the card, the track or the row box. This is documented
  in `foundations/backdrop` ("The declaration has to be true … content between
  the backdrop and the glass is not refracted"). Fixed in the app by wrapping
  them in `GlassBackdrop.live`.
- **C1:** `GlassGroup` asserts "Put the finish on the GlassGroup" when every
  member names a finish. Rule 19 says members' finishes are ignored; the assert
  is the stronger, clearer form of that rule. Not reported.
- **C2:** the ledger's 24 surfaces / 1.77 screens came from the 800×600 test
  view. On the device the same screen reads 16 surfaces, 6 captured, 0.58
  screens, `withinMeasured`.
- **C3:** the Open tab's badge touches the first letter of an inline tab label.
  Cosmetic; apps can use `GlassBadge.offset` with `GlassTabItemLook.inline`.
- **Issue #9** (accessory rim clipped when the tab bar collapses) does not
  reproduce on iOS 26.5 with 0.2.0: `docs/findings/check-issue9-collapsed-accessory.png`.
- **Sheet large detent** settled at 70 pt (safe area 62 + 8) and fully opaque,
  as documented; mid-settle frames looked otherwise.
- **Tooling:** the simulator automation delivered each touch-up one interaction
  late and the simulator's keyboard is a Russian layout. Neither is g1455's.

## Checklist

| Component | What to look at | Result |
|---|---|---|
| `GlassHost` (precache, richBackdrop, minLabelContrast, adaptive) | First frame, label colours over glows | OK (adaptive: F01, F02) |
| `GlassScaffold` + scroll edge | Content blurs under top bar while scrolling | OK |
| `GlassBar` | Rim, label colour, no hard edges | OK |
| `GlassSearchBar` | Cancel slide in/out, clear button | Not checked on device (widget test covers Cancel) |
| `GlassBadge` (Open tab, Lab dot) | Position, count updates, hides at 0 | OK (C3 cosmetic) |
| `GlassButtonGroup` header toolbar | Disabled state | OK |
| `GlassStepper` | Halves, disabled at limits | OK; held repeat not checked |
| Sheet detents (editor, Lab) | Medium ⇄ large drag, opaque large finish | OK |
| `GlassGroup` priority blobs | Selected size change | OK (blobs too far apart to fuse: our layout) |
| `GlassConcentric` field radius | Corners concentric with the sheet | OK |
| `GlassMorph` quick-add | "+" ⇄ panel morph | OK |
| `GlassTextField` | Text legibility inside the morph | OK |
| `GlassSegmentedControl` | Drop drag between segments | Not checked on device |
| `GlassTabBar` collapse + accessory | Collapse, inline accessory, issue #9 | OK (#9 not reproduced); F01 |
| `GlassPageControl` + `GlassAbove` | Dots over glass tip cards | OK (render); tap/drag not checked |
| `GlassBackdrop.painter` / `.live` | List glass vs what's behind, bars refract the list | OK after M1 |
| `GlassSurface` + `GlassTravel` lens | Lens slides, materializes in | OK after M1 |
| `GlassSwitch` / `GlassSlider` | Toggle, sync | OK; F03 |
| `GlassMenuAnchor`, `GlassPopoverAnchor`, `GlassAlert` | Grow-in, dim, dismiss | Not checked on device (widget tests cover them) |
| Lab: finishes | auto / clear / frosted | OK (dark/light not run) |
| Lab: tiers | Opaque and cheap fills | OK (cheap shows sharp content through bars, as documented) |
| Lab: ripple, press swell, drop stretch | Visible effect | Not checked on device |
| Lab: adaptive, high contrast | Branch, outline | Adaptive: F01, F02; high contrast OK |
| Lab: debug outlines | Outlines appear | OK; F03 |
| Lab: glass rows | Bars over glass cards still refract them | OK |
| Lab: ledger readout | Numbers plausible | OK on device (C2) |

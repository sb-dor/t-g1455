# g1455 todo app: full component coverage

Date: 2026-10-16
Status: approved design, awaiting spec review

## Purpose

Extend the existing todo app so it uses as much of the
[g1455](https://pub.dev/packages/g1455) package as a real app would, then use
it to find bugs in g1455 and report them to
[PlugFox/g1455](https://github.com/PlugFox/g1455/issues).

The todo features exist to drive the glass components. They stay simple.

Success means:

- every component and foundation listed in "Coverage" is used in the app;
- each suspected bug is checked against the package's documented rules and
  common errors before it is called a bug;
- each confirmed bug has a standalone minimal reproduction and an issue draft
  ready to file.

## Constraints

- g1455 0.2.0 (upgraded from 0.1.4 in commit `c159ab8`; analyze clean, 8 tests
  pass). Bugs only count if they reproduce on 0.2.0.
- Flutter 3.47.1 stable.
- Primary platform: iOS Simulator (Impeller, Metal). Secondary: macOS desktop,
  used only to check whether a bug is iOS-specific.
- Follow the 27 rules in the package's agent skill
  (`https://g1455.plugfox.dev/.well-known/agent-skills/g1455/SKILL.md`). A bug
  found while breaking a rule is our bug, not the package's.
- Parameter names come from the docs pages, never guessed.
- `flutter analyze` stays clean and all tests pass after every build step.

## Approach

Two parts:

1. **Components inside the todo screens.** Each component goes where a real
   todo app would use it, so bugs from components interacting (glass on
   glass, a collapsing tab bar over a declared backdrop) show up.
2. **A Glass Lab sheet.** Live switches for the global foundations, so a
   suspected bug can be toggled on the simulator without editing code.

Rejected: one demo screen per component. It repeats the docs site and misses
interaction bugs.

## Coverage

Already used before this work: `GlassHost` (with `precache`, `richBackdrop`,
`minLabelContrast`, `adaptive`), `GlassScaffold`, `GlassBar`, `GlassTabBar`,
`GlassButtonGroup` / `GlassToolbarItem`, `GlassPopoverAnchor`,
`GlassSegmentedControl`, `GlassSwitch`, `GlassTextField.search`, `GlassCard`,
`showGlassDialog` / `GlassAlert`, `showGlassSheet`, `GlassMenuAnchor` /
`GlassMenuItem`, `GlassSlider`, `GlassButton`, `GlassTheme.of(...).legibility()`.

New uses:

| Component | Todo feature |
|---|---|
| `GlassSearchBar` | Replaces `GlassTextField.search` at the top of the list; Cancel clears the query. |
| `GlassTextField` | The title input in the quick-add morph panel. |
| `GlassMorph` | The floating action: a "+" capsule that flows into a quick-add panel (title field, priority segmented control, Add button) and back. |
| `GlassButtonGroup` (moved) | A toolbar row in the list header: "Complete all" and "Clear completed". Leaves the floating action slot to the morph. |
| `GlassBadge` | Open-task count on the "Open" tab via `GlassTabItem.iconBuilder`; a dot on the Lab button while `LabSettings.hasChanges`. |
| `GlassTabBar.minimizeBehavior` | `GlassTabBarMinimizeBehavior.onScrollDown`; `GlassScaffold` is the minimizer. |
| `GlassTabBar.bottomAccessory` | A "Next up: <task title>" pill (first open task in the current sort); hidden when there are no open tasks. Re-checks open issue #9 on this setup. |
| `showGlassSheet` detents | The editor opens at `GlassSheetDetent.medium` and can be pulled to `GlassSheetDetent.large`. |
| `GlassStepper` | New task field `estimate`: 1 to 10 pomodoros, step 1, in the editor. |
| `GlassPageControl` | A 3-page tips carousel (`PageView`) on the empty state. Each page is a `GlassCard`; the page control floats over them. |
| `GlassBackdrop.painter` | The page gradient becomes a declared backdrop with a `GradientProxyPainter`. |
| `GlassBackdrop.live` | Wraps the scrolling body so the bars over the list still capture the list. |
| `GlassSurface` + `GlassTravel` + `materialize` | A progress lens in the stats card: a clear, text-free (`labelled: false`) capsule that slides along a track to `completed / total`, inside a `GlassTravel` with `RepaintBoundary`s per rule 8, and materializes in on first build. |
| `GlassGroup` | The editor's three priority markers become small text-free glass blobs in a `GlassGroup` with `spacing` set so the selected blob fuses with its neighbour. Replaces the coloured dot row only; the slider stays. |
| `GlassAbove` | Wraps the tips carousel's `GlassPageControl`, which is sibling glass over the `GlassCard` pages (rule 7). |
| Lab "Glass rows" | Turns todo rows into `GlassCard`s, so the scaffold's bars float over sibling glass. Rule 7 says `GlassScaffold` lifts its bars itself; this checks that claim. |
| `GlassConcentric` | Radius of the text fields inside the editor sheet, from `kGlassSheetRadius` and the sheet's padding, replacing the hard-coded 18. |
| `GlassFinish` | Lab: regular (null), `.regularDark`, `.regularLight`, `.clear`, `.frosted`, passed to `GlassHost.finish`. |
| `GlassTierPolicy` / `GlassTier` | Lab: "Reduce transparency" and "Low-end device (cheap ceiling)" switches, into `GlassTierPolicy(...).choose()` on `GlassHost.tier`. Never `pinned`. |
| `GlassRipple` | Lab: on/off, `GlassHost.ripple`. |
| `GlassDropMotion` | Lab: `maxStretch` slider 0 to 0.5 (0 means `GlassDropMotion.none`), `GlassHost.dropMotion`. |
| `GlassPress` | Lab: press swell on/off (`GlassPress()` / `GlassPress.none`), `GlassHost.press`. |
| `GlassAdaptive` | Lab: adaptive on/off (on by default, as today). |
| `highContrast` | Lab: on/off, `GlassHost.highContrast`. |
| `debugPaintGlassSurfaces` | Lab: debug outlines on/off. |
| `GlassLedger` | Lab: live readout of surface count, captured surface count, screens of glass and verdict, from `GlassScope.maybeOf(context)?.read(...)`. |

Out of scope: `GlassProxy` (the app has no video, map or platform view) and
`GlassUnion` (same idea as `GlassGroup`).

## Files and data flow

```
lib/
  main.dart                    App, GlassHost wiring, TodoPage
  todo_item.dart               + estimate (int, 1–10, default 1)
  todo_controller.dart         + estimate on add/update, completeAll(),
                                 openCount, nextUp
  todo_editor_sheet.dart       + GlassStepper, GlassGroup priority blobs,
                                 GlassConcentric radii; TodoDraft gains estimate
  lab/lab_settings.dart        LabSettings (ChangeNotifier)
  lab/lab_sheet.dart           Lab UI and ledger readout
  widgets/todo_row.dart        _TodoRow moved out of main.dart, made public
  widgets/quick_add_morph.dart QuickAddMorph
  widgets/progress_lens.dart   ProgressLens
  widgets/tips_carousel.dart   TipsCarousel
```

`_AppState` owns two notifiers:

- `TodoController`: the tasks, as today.
- `LabSettings`: `finish`, `reduceTransparency`, `cheapCeiling`, `ripple`,
  `dropStretch`, `press`, `adaptive`, `highContrast`, `debugOutlines`,
  `glassRows`, and `hasChanges` (any field differs from its default) plus
  `reset()`.

A `ListenableBuilder` on `LabSettings` inside `MaterialApp.builder` rebuilds
`GlassHost` from it, so Lab changes apply to the whole app, modals included.
The host stays the only one, above the navigator (rule 1).

`debugOutlines` sets the top-level `debugPaintGlassSurfaces` and schedules a
repaint; it has an effect only in debug builds.

`TodoPage`:

- The page background is `GlassBackdrop.painter` with the existing gradient;
  the two glow circles stay painted inside it.
- The `GlassScaffold` body is wrapped in `GlassBackdrop.live`.
- The top bar gets a Lab button (plain `Icon` in a `GestureDetector`, rule 4)
  wrapped in a `GlassBadge` dot, next to the filter popover.
- The tab bar rebuilds only when its selection, the open count or the next-up
  title changes (rule 24), not on every controller notification. This keeps
  performance findings honest.

## Bug workflow

1. **Log.** Every suspected bug gets an entry in `docs/g1455-findings.md`:
   ID (`F01`, `F02`, ...), component, environment (g1455 0.2.0, Flutter
   3.47.1, simulator model and iOS version), steps, expected, actual,
   screenshot path under `docs/findings/`, status (suspected, confirmed, not a
   bug, reported #N).
2. **Rule out misuse.** Check the symptom against
   `https://g1455.plugfox.dev/start/common-errors` and the 27 rules. If it is
   our misuse, fix our code and mark it "not a bug". If the docs caused the
   misuse, record it as a possible docs issue.
3. **Minimal reproduction.** Each confirmed bug gets
   `repro/<id>_<slug>.dart` with its own `main()`, runnable with
   `flutter run -t repro/<id>_<slug>.dart`, using nothing outside Flutter and
   g1455.
4. **Issue draft.** `docs/issues/<id>.md` in the format of issue #9: summary,
   environment, steps, expected, actual, minimal code, screenshots.
5. **Filing.** The user files issues. Claude files a specific issue with `gh`
   only when the user says so for that issue.

Before drafting, search the repo's existing issues for duplicates.

## Testing

- Write tests first for each new behaviour (tests in `test/`, split by area
  once `widget_test.dart` grows past one area):
  - stepper changes the draft's estimate, and the saved task shows it;
  - search bar filters the list, Cancel clears the query;
  - the "Open" tab badge shows the open count and updates on complete;
  - the morph quick-add opens, adds a task, and closes;
  - the editor sheet opens at medium and reports large after a drag up
    (`onDetentChanged`);
  - the page control turns the tips carousel;
  - with "Glass rows" on, rows are `GlassCard`s and the bars still build;
  - "Complete all" completes every task;
  - the next-up accessory shows the first open task and hides when none;
  - Lab switches reach the host (read back via `GlassTheme.of(context)`) and
    the badge dot follows `hasChanges`; `reset()` clears it.
- Per the docs: pump one extra frame before asserting on glass; the test tree
  keeps `GlassHost` above the `Navigator`.
- The 8 existing tests keep passing, with selectors updated only where a
  widget is deliberately replaced (search field to search bar).
- Visual bugs (holes, grey boxes, clipping, flicker, captures every frame) are
  out of reach of widget tests. They are covered by a manual simulator pass
  with a per-component checklist in `docs/g1455-findings.md`.

## Build order

The app stays runnable and green after each step.

1. Model and controller: `estimate`, `completeAll()`, `openCount`, `nextUp`.
2. Move `_TodoRow` to `widgets/todo_row.dart`.
3. Search bar, Open-tab badge, header toolbar row.
4. Editor: stepper, detents, priority group, concentric radii.
5. Quick-add morph as the floating action.
6. Tab bar collapse on scroll and next-up accessory.
7. Tips carousel on the empty state, page control in `GlassAbove`.
8. Declared backdrop and `GlassBackdrop.live`.
9. Progress lens.
10. Lab settings, Lab sheet, ledger readout, glass rows switch.
11. Simulator pass, findings log, repros and issue drafts.

## Done when

- Every row of "Coverage" is in the app.
- `flutter analyze` is clean and all tests pass.
- The simulator pass is complete and every checklist item has a result.
- Every confirmed finding has a repro file and an issue draft.

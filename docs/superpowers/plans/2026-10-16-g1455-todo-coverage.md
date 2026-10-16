# g1455 Todo Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing todo app so it uses every g1455 0.2.0 component listed in the spec, then run a simulator pass to find, reproduce and draft g1455 bugs.

**Architecture:** Two `ChangeNotifier`s owned by `_AppState`: `TodoController` (tasks) and `LabSettings` (glass config that rebuilds the one `GlassHost` in `MaterialApp.builder`). Components are placed where a real todo app would use them; a Glass Lab sheet toggles the global foundations live.

**Tech Stack:** Flutter 3.47.1, Dart 3.13, g1455 0.2.0, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-16-g1455-todo-coverage-design.md`

## Global Constraints

- g1455 `^0.2.0` (resolved 0.2.0), Flutter 3.47.1. Add no other dependencies.
- Exactly one `GlassHost`, in `MaterialApp.builder` (rule 1). No `GlassTheme` above it.
- Parameter names come from the g1455 docs/source, never guessed. Docs: `https://g1455.plugfox.dev/<section>/<page>.md`; source: `~/.pub-cache/hosted/pub.dev/g1455-0.2.0/lib/src/surface/`.
- Never ship diagnostics: no `content: GlassContentDeclaration.undeclared`, `maxCaptures`, `resolution`, `blurPass`, `glass_diagnostics.dart`, or `GlassTierPolicy(pinned:)`.
- No glass inside `Opacity`, `FadeTransition`, `ColorFilter` or `ImageFiltered` (rule 21). Do not hard-code text/icon colours inside glass components (rule 4); use plain `Icon` in a `GestureDetector` for icon buttons on glass, not Material `IconButton`.
- `flutter analyze` reports `No issues found!` and `flutter test` passes after every task.
- Widget tests pump at least one extra frame before asserting on glass.
- Code style: match the existing files (explicit types, `const` where possible, trailing commas, `ValueKey<String>` test keys in kebab-case).
- Commit after each task with a message ending in `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. Quick-add with an empty or whitespace-only title: no task is added and the panel stays open (test in Task 5).
2. An estimate outside 1–10 reaching the controller: it is clamped, never stored out of range (test in Task 1).
3. A very long task title in the next-up accessory: one line with an ellipsis, no overflow error (test in Task 6).
4. Deleting or completing the task shown as next up: the accessory moves to the next open task or disappears (test in Task 6).
5. Lab "Reset": every setting returns to its default and the Lab badge dot hides (test in Task 10).

---

### Task 1: Model and controller

**Files:**
- Modify: `lib/todo_item.dart`
- Modify: `lib/todo_controller.dart`
- Create: `test/todo_controller_test.dart`

**Interfaces:**
- Produces:
  - `TodoItem.estimate` (`int`, default `1`), `TodoItem.copyWith({..., int? estimate})`
  - `const int kMinEstimate = 1; const int kMaxEstimate = 10;` in `todo_item.dart`
  - `TodoController.addTask({required String title, String notes = '', TodoPriority priority = TodoPriority.medium, int estimate = 1})`
  - `TodoController.updateTask(int id, {required String title, required String notes, required TodoPriority priority, required int estimate})`
  - `int get openCount`: tasks not completed
  - `TodoItem? get nextUp`: the first open task among **all** tasks (ignores view, query and showCompleted) in the current sort order; `null` when none
  - `void completeAll()`: completes every task; notifies once, and not at all when nothing changed

- [ ] **Step 1: Write the failing tests** in `test/todo_controller_test.dart`:
  - `addTask stores the estimate` → `addTask(title: 'A', estimate: 3)`; `items.single.estimate == 3`
  - `estimate is clamped to 1–10` → `estimate: 0` stores `1`; `estimate: 42` stores `10`; `updateTask(..., estimate: -5)` stores `1`
  - `openCount counts tasks not completed` → add 3, complete 1 → `openCount == 2`
  - `nextUp follows the sort and skips completed tasks` → add 'Zulu' then 'Apple'; newest sort → `nextUp!.title == 'Apple'`; `selectSort(TodoSort.title)` → `'Apple'`; complete Apple → `'Zulu'`; complete Zulu → `null`
  - `nextUp ignores the query and the view` → add 'Apple'; `setQuery('zzz')`; `selectView(TodoView.done)` → `nextUp!.title == 'Apple'`
  - `completeAll completes every task and notifies once` → add 2; listener counter; `completeAll()` → `completedCount == 2`, counter `== 1`; `completeAll()` again → counter still `1`

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/todo_controller_test.dart`
Expected: FAIL (compile errors: `estimate`, `openCount`, `nextUp`, `completeAll` not defined)

- [ ] **Step 3: Implement** the fields and members listed in Interfaces. Clamp with `estimate.clamp(kMinEstimate, kMaxEstimate)` in both `addTask` and `updateTask`. Reuse the existing sort comparator for `nextUp` (factor it into a private `_compare(TodoItem a, TodoItem b)` used by `visibleItems` too).

- [ ] **Step 4: Fix the existing callers** of `updateTask` in `lib/main.dart` to pass `estimate: item.estimate` (the editor gains its own estimate in Task 4).

- [ ] **Step 5: Run all tests and analyze**

Run: `flutter test && flutter analyze`
Expected: all tests pass (8 existing + 6 new); `No issues found!`

- [ ] **Step 6: Commit** `lib/todo_item.dart lib/todo_controller.dart lib/main.dart test/todo_controller_test.dart` — "Add estimate, next up and complete all to the todo model"

---

### Task 2: Injectable app, TodoRow extraction, test helpers

**Files:**
- Modify: `lib/main.dart` (remove `_TodoRow`, `App` constructor)
- Create: `lib/widgets/todo_row.dart`
- Create: `test/helpers.dart`
- Modify: `test/widget_test.dart` (use helpers)

**Interfaces:**
- Consumes: Task 1 controller.
- Produces:
  - `App({TodoController? controller, super.key})`: uses the given controller or owns one; disposes only one it owns. `const App()` keeps working. (Task 10 adds `LabSettings? lab`.)
  - `class TodoRow extends StatelessWidget { const TodoRow({required TodoItem item, required TodoController controller, bool glass = false, super.key}); }`: the former `_TodoRow` moved verbatim (same keys `todo-toggle-<id>`, `edit-task-<id>`, `task-menu-<id>`); `glass` is wired in Task 11.
  - `test/helpers.dart`: `Future<void> pumpApp(WidgetTester tester, {TodoController? controller})` (pumps `App`, then one extra frame) and `Future<void> addTask(WidgetTester tester, String title)` (the existing `_addTask` body, moved). Task 5 changes `addTask`'s body only.

- [ ] **Step 1: Move** `_TodoRow` to `lib/widgets/todo_row.dart` as `TodoRow`, add the `App` constructor, move the test helper into `test/helpers.dart` and switch `widget_test.dart` to it.

- [ ] **Step 2: Add one test** to `widget_test.dart`: `uses an injected controller` → `TodoController()..addTask(title: 'Seeded')`; `pumpApp(tester, controller: c)`; `find.text('Seeded')` findsOneWidget.

- [ ] **Step 3: Run tests and analyze**

Run: `flutter test && flutter analyze`
Expected: all pass; `No issues found!`

- [ ] **Step 4: Commit** — "Extract TodoRow and make the app's controller injectable"

---

### Task 3: Search bar, Open-tab badge, header toolbar

**Files:**
- Modify: `lib/main.dart` (`_TodoList`, `TodoPage._tabs`)
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `openCount`, `completeAll()` (Task 1); `pumpApp`, `addTask` (Task 2).
- Produces: keys `task-search-field` (now on `GlassSearchBar`), `open-tab-badge` (the `GlassBadge` on the Open tab), `header-toolbar` (the `GlassButtonGroup`).

- [ ] **Step 1: Write the failing tests:**
  - `cancel clears the search` → add 'Buy groceries', 'Call the dentist'; `enterText(find.byKey(task-search-field), 'grocer')`; pump; dentist findsNothing; `tap(find.text('Cancel'))`; pump 300 ms → both tasks found
  - `open tab badge shows the open count` → add 2 tasks; `tester.widget<GlassBadge>(find.byKey(open-tab-badge)).count == 2`; complete task 1 → `count == 1`
  - `complete all completes every task` → add 2; `tap(find.byIcon(Icons.done_all))`; pump → `find.text('2 of 2 complete')` findsOneWidget
  - The existing `searches tasks by title` and `clears completed tasks` tests must keep passing unchanged.

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/widget_test.dart`
Expected: the 3 new tests FAIL (no `Cancel`, no badge key, no `done_all` icon)

- [ ] **Step 3: Implement:**
  - Replace `GlassTextField.search` with `GlassSearchBar(key: task-search-field, placeholder: 'Search tasks', onChanged: controller.setQuery, onCancel: () => controller.setQuery(''))`, on its own row (rule 23).
  - The Open tab becomes `GlassTabItem(label: 'Open', iconBuilder: (context, look) => GlassBadge(key: open-tab-badge, count: controller.openCount, child: Icon(Icons.radio_button_unchecked, color: look.color, size: look.iconSize)))`. `_tabs` stops being `static const`; build it from the controller.
  - Under the stats card, a `GlassButtonGroup(key: header-toolbar)` with `GlassToolbarItem(icon: Icon(Icons.done_all), label: 'Complete all', onPressed: openCount == 0 ? null : controller.completeAll)` and the "Clear completed" item moved from the floating action. The floating action keeps only "Add task" until Task 5.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add glass search bar, open-tab badge and header toolbar"

---

### Task 4: Editor sheet: stepper, detents, priority group, concentric radii

**Files:**
- Modify: `lib/todo_editor_sheet.dart`
- Modify: `lib/main.dart` (both editor call sites)
- Modify: `lib/widgets/todo_row.dart` (show estimate, open via helper)
- Create: `test/editor_test.dart`

**Interfaces:**
- Consumes: `estimate`, `kMinEstimate`, `kMaxEstimate`, `updateTask(..., estimate:)` (Task 1).
- Produces:
  - `TodoDraft.estimate` (`int`); `TodoEditorSheet({..., int initialEstimate = 1})`
  - `Future<TodoDraft?> showTodoEditor(BuildContext context, {String heading = 'New task', String submitLabel = 'Add task', String initialTitle = '', String initialNotes = '', TodoPriority initialPriority = TodoPriority.medium, int initialEstimate = 1})` in `todo_editor_sheet.dart`. It calls `showGlassSheet` with `detents: <GlassSheetDetent>[GlassSheetDetent.medium, GlassSheetDetent.large]` and `barrierLabel: 'Close task editor'`. Both call sites in `main.dart`/`todo_row.dart` use it.
  - Keys: `estimate-stepper`, `priority-blob-low`, `priority-blob-medium`, `priority-blob-high`.
  - Row copy: `'<n> pomodoro'` when n == 1, else `'<n> pomodoros'`.

- [ ] **Step 1: Write the failing tests** in `test/editor_test.dart` (use `pumpApp`, `addTask`):
  - `stepper sets the estimate` → open the editor on task 1 (`edit-task-1`); expect `find.text('Estimate: 1 pomodoro')`; `tapAt(getCenterRight(find.byKey(estimate-stepper)) - const Offset(12, 0))` twice; expect `'Estimate: 3 pomodoros'`; tap 'Save changes'; pump 700 ms → `find.text('3 pomodoros')` findsOneWidget in the list
  - `stepper stops at 10` → open editor; tap plus 12 times → `'Estimate: 10 pomodoros'`
  - `priority blobs select the priority` → open editor; `tap(find.byKey(priority-blob-high))`; pump → `find.text('High priority')`
  - `editor pulls up to the large detent` → open editor; record `y0 = getTopLeft(find.text('Edit task')).dy`; `drag(find.text('Edit task'), const Offset(0, -600))`; pump 600 ms → `getTopLeft(...).dy < y0 - 100`
  - `fields use the concentric radius` → open editor; `(Theme.of(tester.element(find.byKey(task-title-field))).inputDecorationTheme.border! as OutlineInputBorder).borderRadius == BorderRadius.circular(GlassConcentric.radius(kGlassSheetRadius, 20))`

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/editor_test.dart`
Expected: FAIL (no stepper, no blobs, no `showTodoEditor`)

- [ ] **Step 3: Implement:**
  - Stepper row: `Expanded(Text('Estimate: $label'))` + `GlassStepper(key: estimate-stepper, value: _estimate.toDouble(), min: kMinEstimate.toDouble(), max: kMaxEstimate.toDouble(), semanticLabel: 'Estimate in pomodoros', onChanged: (v) => setState(() => _estimate = v.round()))`.
  - Priority blobs: replace the trailing `Text('<p> priority')` row's leading flag with a `GlassGroup(spacing: 8, labelled: false, child: Row(...))` of three `GestureDetector` + `SizedBox.square(GlassSurface(borderRadius: kGlassCapsule, finish: GlassFinish.clear, labelled: false))`: 26 px for the selected priority, 14 px otherwise, 6 px gaps. A tap sets `_priority` to that priority's slider value (0.15 / 0.5 / 0.85). The slider stays and gets `divisions: 2` with values 0, 0.5, 1 (rule 14: no rounding in `onChanged`); map 0/0.5/1 to low/medium/high and use those three values for the blobs too.
  - Field radius: `BorderRadius.circular(GlassConcentric.radius(kGlassSheetRadius, 20))`, where 20 is the sheet content's horizontal padding.
  - Keep `MediaQuery.viewInsetsOf(context).bottom` in the padding: in 0.2.0 the sheet removes the keyboard inset from its content, so it reads 0 there and the sheet itself stands on the keyboard.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add estimate stepper, priority glass group and detents to the editor"

---

### Task 5: Quick-add morph

**Files:**
- Create: `lib/widgets/quick_add_morph.dart`
- Modify: `lib/main.dart` (`floatingAction`)
- Modify: `test/helpers.dart` (`addTask` body)
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `showTodoEditor` (Task 4), `controller.addTask` (Task 1).
- Produces: `class QuickAddMorph extends StatefulWidget { const QuickAddMorph({required TodoController controller, super.key}); }`. Keys: `quick-add-button` (closed "+"), `quick-add-field` (`GlassTextField`), `quick-add-submit` (`GlassButton` "Add"), `quick-add-details` ("More details"), `quick-add-close` (close icon).

- [ ] **Step 1: Write the failing tests:**
  - `quick add adds a task and closes` → tap `quick-add-button`; pump 400 ms; `enterText(quick-add-field, 'Water plants')`; tap `quick-add-submit`; pump 400 ms → `find.text('Water plants')` findsOneWidget; `find.byKey(quick-add-field)` findsNothing; `find.byKey(quick-add-button)` findsOneWidget
  - `quick add ignores a blank title` (Review Focus 1) → open; `enterText(quick-add-field, '   ')`; tap submit → `controller.items` is empty and `quick-add-field` still found
  - `more details opens the full editor with the title` → open; enter 'Plan trip'; tap `quick-add-details`; pump 400 ms → `find.text('New task')` findsOneWidget and `tester.widget<TextField>(find.byKey(task-title-field)).controller!.text == 'Plan trip'`
  - Update `adds a task from the glass editor sheet` to reach the editor through `quick-add-details`.
  - Change `test/helpers.dart` `addTask` to use the quick-add (tap button, enter text, tap submit, pump 400 ms).

- [ ] **Step 2: Run to verify they fail.** Run: `flutter test`. Expected: the new tests FAIL; old tests using `addTask` FAIL until Step 3.

- [ ] **Step 3: Implement** `QuickAddMorph`: `GlassMorph(alignment: Alignment.bottomRight, borderRadius: _open ? const BorderRadius.all(Radius.circular(28)) : kGlassCapsule, child: _open ? panel : plus)`. Closed: a 56×56 `GestureDetector` with `Icon(Icons.add)` and `Semantics(button: true, label: 'Add task')`. Open (`ValueKey('panel')`, width 300): `GlassTextField(key: quick-add-field, placeholder: 'New task', autofocus: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _submit())`, a `GlassSegmentedControl` with Low/Medium/High (default Medium), and a row with "More details" (plain text in a `GestureDetector`), a close `Icon(Icons.close)` and `GlassButton(key: quick-add-submit, child: Text('Add'))`. `_submit` trims, does nothing when empty, otherwise `addTask(title:, priority:)`, clears the field and closes. "More details" closes the morph, then `showTodoEditor(context, initialTitle: <text>, initialPriority: <selected>)` and adds the returned draft (with its estimate).

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add quick-add glass morph as the floating action"

---

### Task 6: Tab bar collapse, next-up accessory, scoped rebuilds

**Files:**
- Modify: `lib/main.dart` (`TodoPage.build`; new private `_TabBarSection`)
- Create: `test/tab_bar_test.dart`

**Interfaces:**
- Consumes: `nextUp`, `openCount` (Task 1); `pumpApp` (Task 2).
- Produces: key `next-up-accessory`. `TodoPage` no longer wraps the whole `GlassScaffold` in a `ListenableBuilder`: the body has its own `ListenableBuilder`, and `bottomBar` is a `_TabBarSection` (stateful, listens to the controller) that calls `setState` only when `(view.index, openCount, nextUp?.id, nextUp?.title)` changes.

- [ ] **Step 1: Write the failing tests** in `test/tab_bar_test.dart` (seed via an injected controller):
  - `next up shows the first open task` → seed 'Zulu', 'Apple' → `find.text('Next up: Apple')`
  - `next up follows completion and deletion` (Review Focus 4) → seed 'Zulu', 'Apple'; `c.setCompleted(2, true)`; pump → `'Next up: Zulu'`; `c.deleteTask(1)`; pump → `find.byKey(next-up-accessory)` findsNothing
  - `long next-up titles stay on one line` (Review Focus 3) → seed a 200-character title; pump → `tester.takeException()` is null; the accessory's `Text` has `maxLines == 1` and `overflow == TextOverflow.ellipsis`
  - `tab bar is not rebuilt when its inputs are unchanged` → seed 'A'; `final GlassTabBar before = tester.widget(find.byType(GlassTabBar))`; `c.updateTask(1, title: 'A', notes: 'note', priority: TodoPriority.medium, estimate: 1)`; pump → `identical(before, tester.widget(find.byType(GlassTabBar)))` is true
  - `tab bar collapses on scroll down` → seed 20 tasks; `drag(find.byType(ListView), const Offset(0, -300))`; pump 400 ms → `find.text('All')` findsNothing (the collapsed bar shows only the selected icon); drag back `+300`; pump 400 ms → `find.text('All')` findsOneWidget

- [ ] **Step 2: Run to verify they fail.** Run: `flutter test test/tab_bar_test.dart`. Expected: FAIL.

- [ ] **Step 3: Implement:** `GlassTabBar(minimizeBehavior: GlassTabBarMinimizeBehavior.onScrollDown, bottomAccessory: nextUp == null ? null : _NextUp(title))`, where `_NextUp` is `Row(Icon(Icons.flag_outlined), Expanded(Text('Next up: $title', key: next-up-accessory, maxLines: 1, overflow: TextOverflow.ellipsis)))`. `GlassScaffold` is the minimizer; no extra `GlassTabBarMinimizer`.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`. If the collapse test fails because collapsed labels are still in the tree, first check `components/tab-bar.md` for what collapsed renders; adjust the assertion to the documented behaviour, and log it as a finding candidate if the docs and behaviour disagree.

- [ ] **Step 5: Commit** — "Collapse the tab bar on scroll and add a next-up accessory"

---

### Task 7: Tips carousel with page control

**Files:**
- Create: `lib/widgets/tips_carousel.dart`
- Modify: `lib/main.dart` (`_EmptyTodos`)
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `class TipsCarousel extends StatefulWidget { const TipsCarousel({super.key}); }` (owns and disposes its `PageController`). Copy, in order: `'Tap + to add a task'`, `'Pull the editor up for long notes'`, `'Tune the glass in the Lab'`.

- [ ] **Step 1: Write the failing test** `tips carousel turns with the page control` → `pumpApp`; `find.text('Tap + to add a task')` found; `tapAt(getCenterRight(find.byType(GlassPageControl)) - const Offset(8, 0))`; pump 400 ms → `find.text('Pull the editor up for long notes')` found. The existing empty-state test keeps expecting `'No tasks yet'`.

- [ ] **Step 2: Run to verify it fails.** Expected: FAIL (no carousel).

- [ ] **Step 3: Implement:** a 160 px tall `Stack`: `PageView` of three `GlassCard`s (one tip each, centred text), with `Positioned(bottom: 8, left: 0, right: 0, child: Center(child: GlassAbove(child: GlassPageControl(count: 3, controller: _pages, semanticLabel: 'Tips'))))`. `_EmptyTodos` shows the icon, `'No tasks yet'`, then the carousel (replacing `'Tap + to add your first task.'`).

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add a tips carousel with a glass page control"

---

### Task 8: Declared backdrop

**Files:**
- Modify: `lib/main.dart` (`_TodoBackdrop`, `TodoPage.build`)
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `const GradientProxyPainter kTodoGradient` (top level in `main.dart`) holding the existing `LinearGradient` (topLeft→bottomRight, `0xFF11131C`, `0xFF252044`, `0xFF172F3D`).

- [ ] **Step 1: Write the failing test** `bars capture and list glass reads the declaration` → `pumpApp`; `GlassBackdrop.maybeOf(tester.element(find.text('My Tasks')))` is null; `GlassBackdrop.maybeOf(tester.element(find.text('No tasks yet')))` is not null.

- [ ] **Step 2: Run to verify it fails.** Expected: FAIL (both null today).

- [ ] **Step 3: Implement** the structure from the spec's "Files and data flow": `GlassBackdrop.painter(kTodoGradient, child: Stack(glows, GlassBackdrop.live(child: GlassScaffold(..., body: GlassBackdrop.painter(kTodoGradient, paintBackdrop: false, child: body)))))`. The glows stay as ordinary content in the stack under the live scaffold.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Declare the page gradient as the glass backdrop"

---

### Task 9: Progress lens

**Files:**
- Create: `lib/widgets/progress_lens.dart`
- Modify: `lib/main.dart` (stats card)
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `class ProgressLens extends StatelessWidget { const ProgressLens({required double progress, super.key}); }`. `progress` is clamped to 0–1. Track height 44, lens 44×44, key `progress-lens` on the lens, key `progress-track` on the track. Constants: `kLensSize = 44`, `kLensDuration = Duration(milliseconds: 350)`.

- [ ] **Step 1: Write the failing test** `progress lens sits at the completed fraction` → seed 2 tasks, complete 1; pump 600 ms; `track = tester.getRect(find.byKey(progress-track))`; expect `getCenter(find.byKey(progress-lens)).dx` within 1.0 of `track.left + 22 + (track.width - 44) * 0.5`.

- [ ] **Step 2: Run to verify it fails.** Expected: FAIL.

- [ ] **Step 3: Implement:** `GlassTravel(child: Stack(RepaintBoundary(track: a rounded translucent bar), AnimatedPositioned(duration: kLensDuration, curve: Curves.easeOutCubic, left: (width - 44) * progress, child: RepaintBoundary(TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: 400 ms, builder: (_, m, __) => SizedBox.square(dimension: 44, child: GlassSurface(key: progress-lens, borderRadius: kGlassCapsule, finish: GlassFinish.clear, labelled: false, materialize: m)))))))`, with `LayoutBuilder` for width. Add it under the stats card's text, with `progress = items.isEmpty ? 0 : completedCount / items.length`, and a `Semantics(label: '<percent>% complete')`.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add a travelling glass progress lens"

---

### Task 10: Lab settings and host wiring

**Files:**
- Create: `lib/lab/lab_settings.dart`
- Modify: `lib/main.dart` (`App`, `_AppState`, host builder)
- Create: `test/lab_settings_test.dart`

**Interfaces:**
- Produces:
  - `enum LabFinish { auto, dark, light, clear, frosted }` with `GlassFinish? get glassFinish` (`null`, `.regularDark`, `.regularLight`, `.clear`, `.frosted`) and `String get label` (`'Auto'`, `'Dark'`, `'Light'`, `'Clear'`, `'Frosted'`)
  - `class LabSettings extends ChangeNotifier` with fields (default): `finish` (`LabFinish.auto`), `reduceTransparency` (false), `cheapCeiling` (false), `ripple` (false), `dropStretch` (`0.12`, range 0–0.5), `press` (true), `adaptive` (true), `highContrast` (false), `debugOutlines` (false), `glassRows` (false). Each has a setter `void setX(T value)` that notifies only on change.
  - Derived: `GlassTierChoice get tier` (`GlassTierPolicy(reduceTransparency: reduceTransparency, ceiling: cheapCeiling ? GlassTier.cheap : null).choose()`), `GlassRipple? get glassRipple`, `GlassDropMotion get dropMotion` (`GlassDropMotion.none` at 0, else `GlassDropMotion(maxStretch: dropStretch)`), `GlassPress get glassPress`, `GlassAdaptive? get glassAdaptive`, `bool? get glassHighContrast` (`true` or `null`, so the OS setting still applies).
  - `bool get hasChanges`, `void reset()`.
  - `setDebugOutlines` sets the top-level `debugPaintGlassSurfaces` and, in debug builds, calls `WidgetsBinding.instance.reassembleApplication()` so every surface repaints.
  - `App({TodoController? controller, LabSettings? lab, super.key})`; the host builder is `ListenableBuilder(listenable: lab, builder: (_, __) => GlassHost(finish:, tier:, ripple:, dropMotion:, press:, adaptive:, highContrast:, richBackdrop: true, minLabelContrast: kTextContrastAA, backdrop: const Color(0xFF11131C), child: child!))`.

- [ ] **Step 1: Write the failing tests** in `test/lab_settings_test.dart` (`tearDown(() => debugPaintGlassSurfaces = false)`):
  - `defaults have no changes` → `LabSettings().hasChanges` false; `tier.tier == GlassTier.full`; `glassRipple` null; `glassHighContrast` null
  - `reduce transparency picks the opaque tier` → `setReduceTransparency(true)` → `tier.tier == GlassTier.opaque`; `hasChanges` true
  - `cheap ceiling picks the cheap tier` → `tier.tier == GlassTier.cheap`
  - `zero stretch is no drop motion` → `setDropStretch(0)` → `dropMotion.isNone`
  - `reset restores every default` (Review Focus 5) → change every field; `reset()` → `hasChanges` false, `debugPaintGlassSurfaces` false
  - `lab changes reach the host` (widget) → `final lab = LabSettings(); pumpApp(..., lab: lab)`; `lab.setRipple(true); lab.setFinish(LabFinish.frosted)`; pump 2 frames → `GlassTheme.of(tester.element(find.text('My Tasks')))` has `ripple != null` and `finish.name == GlassFinish.frosted.name`
  - Extend `pumpApp` with `LabSettings? lab`.

- [ ] **Step 2: Run to verify they fail.** Expected: FAIL (no `LabSettings`).

- [ ] **Step 3: Implement** as in Interfaces.

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add Lab settings that drive the glass host"

---

### Task 11: Lab sheet, Lab button, ledger readout, glass rows

**Files:**
- Create: `lib/lab/lab_sheet.dart`
- Modify: `lib/main.dart` (top bar Lab button, pass `lab` to `TodoPage` and `TodoRow`)
- Modify: `lib/widgets/todo_row.dart` (`glass`)
- Create: `test/lab_sheet_test.dart`

**Interfaces:**
- Consumes: `LabSettings` (Task 10), `TodoRow.glass` (Task 2).
- Produces: `Future<void> showLabSheet(BuildContext context, LabSettings lab)` (`showGlassSheet` with medium/large detents, `barrierLabel: 'Close Glass Lab'`). Keys: `lab-button`, `lab-badge`, `lab-finish` (segmented control), switch keys `lab-reduce-transparency`, `lab-cheap-ceiling`, `lab-ripple`, `lab-press`, `lab-adaptive`, `lab-high-contrast`, `lab-debug-outlines`, `lab-glass-rows`, slider `lab-drop-stretch`, button `lab-reset`, text `lab-ledger`.

- [ ] **Step 1: Write the failing tests** in `test/lab_sheet_test.dart` (close the sheet with `Navigator.of(tester.element(find.text('Glass Lab'))).pop()` and pump 400 ms before each test ends, so the ledger timer is disposed):
  - `lab badge follows changes` → `tester.widget<GlassBadge>(find.byKey(lab-badge)).isVisible` false; open Lab (`lab-button`, pump 400 ms); tap `lab-ripple`; pump → `isVisible` true; tap `lab-reset`; pump → false
  - `lab switches reach the host` → open Lab; tap `lab-reduce-transparency`; pump 2 frames → `GlassTheme.of(tester.element(find.text('Glass Lab'))).tier.tier == GlassTier.opaque`
  - `ledger reads the glass on screen` → open Lab; pump 1100 ms → the `lab-ledger` text matches `RegExp(r'^\d+ surfaces · \d+ captured · \d+\.\d\d screens · \w+$')`
  - `glass rows turn rows into glass cards` → seed 1 task with an injected `LabSettings()..setGlassRows(true)` → `find.descendant(of: find.byType(TodoRow), matching: find.byType(GlassCard))` findsOneWidget

- [ ] **Step 2: Run to verify they fail.** Expected: FAIL.

- [ ] **Step 3: Implement:**
  - Top bar: before `_FilterPopover`, a 44×44 `GestureDetector(key: lab-button)` with `Semantics(button: true, label: 'Open Glass Lab')` and `ListenableBuilder(lab) → GlassBadge(key: lab-badge, isVisible: lab.hasChanges, child: Icon(Icons.science_outlined))` (no count and no label means a dot).
  - Sheet content in a `ListenableBuilder(lab)`: heading `'Glass Lab'`; `GlassSegmentedControl(key: lab-finish)` over `LabFinish.values` labels; one `MergeSemantics` row per switch (labels: 'Reduce transparency', 'Low-end device', 'Ripple', 'Button press swell', 'Adaptive glass', 'High contrast', 'Debug outlines', 'Glass rows'); `'Drop stretch'` with `GlassSlider(key: lab-drop-stretch, value: dropStretch / 0.5, divisions: 10, onChanged: (v) => lab.setDropStretch(v * 0.5))`; `GlassButton(key: lab-reset, onPressed: lab.hasChanges ? lab.reset : null, child: Text('Reset'))`.
  - `_LedgerReadout` (stateful): `Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}))`, cancelled in `dispose`; reads `GlassScope.maybeOf(context)?.read(viewSize: MediaQuery.sizeOf(context), model: GlassHardware.detect().surfaceCostModel)`; renders `'<surfaceCount> surfaces · <capturedSurfaceCount> captured · <screensOfGlass to 2 dp> screens · <verdict.name>'`, or `'No ledger'` when null.
  - `TodoRow(glass: true)` swaps its `DecoratedBox` for `GlassCard(padding: const EdgeInsets.all(16), child: ...)`, and drops the hard-coded title/notes colours inside it (rule 4).

- [ ] **Step 4: Run tests and analyze.** Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — "Add the Glass Lab sheet with ledger readout and glass rows"

---

### Task 12: Findings scaffolding and simulator pass

**Files:**
- Create: `docs/g1455-findings.md`
- Create: `docs/findings/` (screenshots), `docs/issues/`, `repro/` (as findings need them)

This task is manual. Its deliverable is the findings log, not code.

- [ ] **Step 1: Create `docs/g1455-findings.md`** with:
  - An environment header: g1455 0.2.0, Flutter 3.47.1, simulator model and iOS version (from `xcrun simctl list devices booted`).
  - An entry template with the fields from the spec's "Bug workflow" (ID, component, environment, steps, expected, actual, screenshot, status).
  - A checklist with one line per "Coverage" row, each needing a result: OK, finding ID, or not applicable.

- [ ] **Step 2: Boot the simulator and run the app.** Run: `open -a Simulator`, then `flutter run -d <booted device id>`. Expected: the app launches showing "My Tasks" with glass bars.

- [ ] **Step 3: Walk the checklist.** For each item, exercise it on the simulator. Toggle the relevant Lab settings (finish, tiers, high contrast, glass rows, debug outlines) while watching for holes, grey boxes, clipping, flicker, wrong label colours and stuck animations. Screenshot anything suspect into `docs/findings/<id>.png`.

- [ ] **Step 4: Triage each suspect** per the spec's "Bug workflow": check `start/common-errors.md` and the 27 rules first, then search existing issues (`gh issue list -R PlugFox/g1455 --state all --search "<component>"`). Mark "not a bug" with the reason, fixing our code if it was misuse.

- [ ] **Step 5: For each confirmed finding**, write `repro/<id>_<slug>.dart` (its own `main()`, only Flutter and g1455), confirm it shows the bug with `flutter run -t repro/<id>_<slug>.dart`, then write `docs/issues/<id>.md` in issue #9's format.

- [ ] **Step 6: Run analyze and tests once more.** Run: `flutter analyze && flutter test`. Expected: `No issues found!` and all tests pass. Repro files must analyze cleanly too.

- [ ] **Step 7: Commit** — "Log g1455 simulator findings with repros and issue drafts". Do not file issues: the user files them, or approves a specific `gh issue create`.

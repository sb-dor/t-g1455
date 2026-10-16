import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';
import 'package:t_g1455/lab/lab_sheet.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_item.dart';
import 'package:t_g1455/widgets/progress_lens.dart';
import 'package:t_g1455/widgets/quick_add_morph.dart';
import 'package:t_g1455/widgets/tips_carousel.dart';
import 'package:t_g1455/widgets/todo_backdrop.dart';
import 'package:t_g1455/widgets/todo_row.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({this.controller, this.lab, super.key});

  final TodoController? controller;
  final LabSettings? lab;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final TodoController _controller = widget.controller ?? TodoController();
  late final LabSettings _lab = widget.lab ?? LabSettings();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.lab == null) _lab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C5CFC),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
    ),
    builder: (BuildContext context, Widget? child) => ListenableBuilder(
      listenable: _lab,
      builder: (BuildContext context, Widget? _) => GlassHost(
        finish: _lab.finish.glassFinish,
        tier: _lab.tier,
        ripple: _lab.glassRipple,
        dropMotion: _lab.dropMotion,
        press: _lab.glassPress,
        adaptive: _lab.glassAdaptive,
        highContrast: _lab.glassHighContrast,
        richBackdrop: true,
        minLabelContrast: kTextContrastAA,
        backdrop: const Color(0xFF11131C),
        child: child!,
      ),
    ),
    home: TodoPage(controller: _controller, lab: _lab),
  );
}

class TodoPage extends StatefulWidget {
  const TodoPage({required this.controller, required this.lab, super.key});

  final TodoController controller;
  final LabSettings lab;

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  /// The search field's text. Owned here rather than by the search bar so it
  /// outlives the field: the list swaps for the empty state, or scrolls the
  /// field out of the ListView's cache, and the field is rebuilt from scratch
  /// while [TodoController.query] stays.
  late final TextEditingController _search = TextEditingController(
    text: widget.controller.query,
  );

  @override
  void didUpdateWidget(TodoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _search.text = widget.controller.query;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: GlassBackdrop.painter(
      kTodoBackdrop,
      child: GlassBackdrop.live(
        child: GlassScaffold(
          host: false,
          topBar: GlassBar(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              children: <Widget>[
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'My Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                _LabButton(lab: widget.lab),
                _FilterPopover(controller: widget.controller),
              ],
            ),
          ),
          bottomBar: _TabBarSection(controller: widget.controller),
          floatingAction: QuickAddMorph(controller: widget.controller),
          body: GlassBackdrop.painter(
            kTodoBackdrop,
            paintBackdrop: false,
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                widget.controller,
                widget.lab,
              ]),
              builder: (BuildContext context, Widget? child) =>
                  widget.controller.items.isEmpty
                  ? const _EmptyTodos()
                  : _TodoList(
                      controller: widget.controller,
                      lab: widget.lab,
                      search: _search,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The bottom tab bar. It listens to the controller but rebuilds only when
/// something it draws changes: the selected view, the open count on the badge,
/// or the next-up task shown in the accessory.
class _TabBarSection extends StatefulWidget {
  const _TabBarSection({required this.controller});

  final TodoController controller;

  @override
  State<_TabBarSection> createState() => _TabBarSectionState();
}

class _TabBarSectionState extends State<_TabBarSection> {
  late (int, int, int?, String?) _key;

  static (int, int, int?, String?) _keyOf(TodoController controller) {
    final TodoItem? nextUp = controller.nextUp;
    return (
      controller.view.index,
      controller.openCount,
      nextUp?.id,
      nextUp?.title,
    );
  }

  @override
  void initState() {
    super.initState();
    _key = _keyOf(widget.controller);
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(_TabBarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _key = _keyOf(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final (int, int, int?, String?) key = _keyOf(widget.controller);
    if (key == _key) return;
    setState(() => _key = key);
  }

  @override
  Widget build(BuildContext context) {
    final TodoController controller = widget.controller;
    final int openCount = controller.openCount;
    final String? nextUpTitle = controller.nextUp?.title;
    return GlassTabBar(
      items: <GlassTabItem>[
        const GlassTabItem(icon: Icons.list_alt, label: 'All'),
        GlassTabItem(
          label: 'Open',
          iconBuilder: (BuildContext context, GlassTabItemLook look) =>
              GlassBadge(
                key: const ValueKey<String>('open-tab-badge'),
                count: openCount,
                child: Icon(
                  Icons.radio_button_unchecked,
                  color: look.color,
                  size: look.iconSize,
                ),
              ),
        ),
        const GlassTabItem(icon: Icons.task_alt, label: 'Done'),
      ],
      selectedIndex: controller.view.index,
      onSelected: (int index) => controller.selectView(TodoView.values[index]),
      minimizeBehavior: GlassTabBarMinimizeBehavior.onScrollDown,
      bottomAccessory: nextUpTitle == null ? null : _NextUp(title: nextUpTitle),
    );
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const Icon(Icons.flag_outlined),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Next up: $title',
          key: const ValueKey<String>('next-up-accessory'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _FilterPopover extends StatelessWidget {
  const _FilterPopover({required this.controller});

  final TodoController controller;

  @override
  Widget build(BuildContext context) => GlassPopoverAnchor(
    width: 280,
    radius: 28,
    barrierLabel: 'Close task filters',
    popoverBuilder: (BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Sort tasks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GlassSegmentedControl(
              segments: const <Widget>[Text('Newest'), Text('A–Z')],
              selectedIndex: controller.sort.index,
              onSelected: (int index) =>
                  controller.selectSort(TodoSort.values[index]),
            ),
            const SizedBox(height: 14),
            MergeSemantics(
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Show completed')),
                  GlassSwitch(
                    key: const ValueKey<String>('show-completed-switch'),
                    value: controller.showCompleted,
                    onChanged: controller.setShowCompleted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    builder: (BuildContext context, GlassMenuController popover) => Semantics(
      button: true,
      label: 'Sort and filter tasks',
      child: GestureDetector(
        key: const ValueKey<String>('filter-popover-button'),
        behavior: HitTestBehavior.opaque,
        onTap: popover.open,
        child: const SizedBox.square(dimension: 44, child: Icon(Icons.tune)),
      ),
    ),
  );
}

/// Opens the Glass Lab. A dot on the icon says some setting is off its default.
class _LabButton extends StatelessWidget {
  const _LabButton({required this.lab});

  final LabSettings lab;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open Glass Lab',
    child: GestureDetector(
      key: const ValueKey<String>('lab-button'),
      behavior: HitTestBehavior.opaque,
      onTap: () => showLabSheet(context, lab),
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: ListenableBuilder(
            listenable: lab,
            builder: (BuildContext context, Widget? _) => GlassBadge(
              key: const ValueKey<String>('lab-badge'),
              isVisible: lab.hasChanges,
              child: const Icon(Icons.science_outlined),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.controller,
    required this.lab,
    required this.search,
  });

  final TodoController controller;
  final LabSettings lab;
  final TextEditingController search;

  String get _emptyMessage => controller.query.trim().isNotEmpty
      ? 'No matching tasks'
      : switch (controller.view) {
          TodoView.all => 'No tasks yet',
          TodoView.open => 'No open tasks',
          TodoView.done => 'Nothing completed',
        };

  @override
  Widget build(BuildContext context) {
    final EdgeInsets bars = MediaQuery.paddingOf(context);
    final List<TodoItem> items = controller.visibleItems;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, bars.top + 12, 16, bars.bottom + 12),
      children: <Widget>[
        GlassSearchBar(
          key: const ValueKey<String>('task-search-field'),
          controller: search,
          placeholder: 'Search tasks',
          onChanged: controller.setQuery,
          onCancel: () => controller.setQuery(''),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: <Widget>[
              const Icon(Icons.insights_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${controller.completedCount} of ${controller.items.length} complete',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.completedCount == controller.items.length
                          ? 'Everything is checked off.'
                          : 'One small step at a time.',
                      style: TextStyle(
                        color: DefaultTextStyle.of(context).style.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ProgressLens(
                      progress: controller.items.isEmpty
                          ? 0
                          : controller.completedCount / controller.items.length,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: GlassButtonGroup(
            key: const ValueKey<String>('header-toolbar'),
            items: <GlassToolbarItem>[
              GlassToolbarItem(
                icon: const Icon(Icons.done_all),
                label: 'Complete all',
                onPressed: controller.openCount == 0
                    ? null
                    : controller.completeAll,
              ),
              GlassToolbarItem(
                icon: const Icon(Icons.cleaning_services_outlined),
                label: 'Clear completed',
                onPressed: controller.completedCount == 0
                    ? null
                    : controller.clearCompleted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 72),
            child: Text(
              _emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          )
        else
          for (final TodoItem item in items) ...<Widget>[
            TodoRow(item: item, controller: controller, glass: lab.glassRows),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _EmptyTodos extends StatelessWidget {
  const _EmptyTodos();

  @override
  Widget build(BuildContext context) => ListView(
    children: const <Widget>[
      SizedBox(height: 96),
      Icon(Icons.task_alt, size: 64, color: Color(0x99FFFFFF)),
      SizedBox(height: 18),
      Text(
        'No tasks yet',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      SizedBox(height: 24),
      TipsCarousel(),
    ],
  );
}

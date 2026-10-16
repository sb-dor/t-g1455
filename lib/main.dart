import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_editor_sheet.dart';
import 'package:t_g1455/todo_item.dart';
import 'package:t_g1455/widgets/todo_row.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({this.controller, super.key});

  final TodoController? controller;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final TodoController _controller = widget.controller ?? TodoController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
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
    builder: (BuildContext context, Widget? child) => GlassHost(
      richBackdrop: true,
      minLabelContrast: kTextContrastAA,
      backdrop: const Color(0xFF11131C),
      adaptive: const GlassAdaptive(),
      child: child!,
    ),
    home: TodoPage(controller: _controller),
  );
}

class TodoPage extends StatelessWidget {
  const TodoPage({required this.controller, super.key});

  final TodoController controller;

  List<GlassTabItem> get _tabs => <GlassTabItem>[
    const GlassTabItem(icon: Icons.list_alt, label: 'All'),
    GlassTabItem(
      label: 'Open',
      iconBuilder: (BuildContext context, GlassTabItemLook look) => GlassBadge(
        key: const ValueKey<String>('open-tab-badge'),
        count: controller.openCount,
        child: Icon(
          Icons.radio_button_unchecked,
          color: look.color,
          size: look.iconSize,
        ),
      ),
    ),
    const GlassTabItem(icon: Icons.task_alt, label: 'Done'),
  ];

  Future<void> _openEditor(BuildContext context) async {
    final TodoDraft? draft = await showTodoEditor(context);
    if (draft == null) return;
    controller.addTask(
      title: draft.title,
      notes: draft.notes,
      priority: draft.priority,
      estimate: draft.estimate,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _TodoBackdrop(
      child: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? child) => GlassScaffold(
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
                _FilterPopover(controller: controller),
              ],
            ),
          ),
          bottomBar: GlassTabBar(
            items: _tabs,
            selectedIndex: controller.view.index,
            onSelected: (int index) =>
                controller.selectView(TodoView.values[index]),
          ),
          floatingAction: GlassButtonGroup(
            items: <GlassToolbarItem>[
              GlassToolbarItem(
                icon: const Icon(Icons.add),
                label: 'Add task',
                onPressed: () => _openEditor(context),
              ),
            ],
          ),
          body: controller.items.isEmpty
              ? const _EmptyTodos()
              : _TodoList(controller: controller),
        ),
      ),
    ),
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

class _TodoList extends StatelessWidget {
  const _TodoList({required this.controller});

  final TodoController controller;

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
            TodoRow(item: item, controller: controller),
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
      SizedBox(height: 8),
      Text(
        'Tap + to add your first task.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xB3FFFFFF)),
      ),
    ],
  );
}

class _TodoBackdrop extends StatelessWidget {
  const _TodoBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF11131C),
          Color(0xFF252044),
          Color(0xFF172F3D),
        ],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const Positioned(
          top: 110,
          right: -70,
          child: _Glow(color: Color(0x667C5CFC), size: 240),
        ),
        const Positioned(
          bottom: 80,
          left: -90,
          child: _Glow(color: Color(0x5543D9AD), size: 270),
        ),
        child,
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_item.dart';

const double _kSheetPadding = 20;

class TodoDraft {
  const TodoDraft({
    required this.title,
    required this.notes,
    required this.priority,
    required this.estimate,
  });

  final String title;
  final String notes;
  final TodoPriority priority;
  final int estimate;
}

Future<TodoDraft?> showTodoEditor(
  BuildContext context, {
  String heading = 'New task',
  String submitLabel = 'Add task',
  String initialTitle = '',
  String initialNotes = '',
  TodoPriority initialPriority = TodoPriority.medium,
  int initialEstimate = 1,
}) => showGlassSheet<TodoDraft>(
  context: context,
  barrierLabel: 'Close task editor',
  detents: <GlassSheetDetent>[GlassSheetDetent.medium, GlassSheetDetent.large],
  builder: (BuildContext context) => TodoEditorSheet(
    heading: heading,
    submitLabel: submitLabel,
    initialTitle: initialTitle,
    initialNotes: initialNotes,
    initialPriority: initialPriority,
    initialEstimate: initialEstimate,
  ),
);

class TodoEditorSheet extends StatefulWidget {
  const TodoEditorSheet({
    this.heading = 'New task',
    this.submitLabel = 'Add task',
    this.initialTitle = '',
    this.initialNotes = '',
    this.initialPriority = TodoPriority.medium,
    this.initialEstimate = 1,
    super.key,
  });

  final String heading;
  final String submitLabel;
  final String initialTitle;
  final String initialNotes;
  final TodoPriority initialPriority;
  final int initialEstimate;

  @override
  State<TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<TodoEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late double _priority;
  late int _estimate;

  static double _valueOf(TodoPriority priority) => switch (priority) {
    TodoPriority.low => 0,
    TodoPriority.medium => 0.5,
    TodoPriority.high => 1,
  };

  TodoPriority get _selectedPriority => switch (_priority) {
    < 0.25 => TodoPriority.low,
    < 0.75 => TodoPriority.medium,
    _ => TodoPriority.high,
  };

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _notes = TextEditingController(text: widget.initialNotes);
    _priority = _valueOf(widget.initialPriority);
    _estimate = widget.initialEstimate.clamp(kMinEstimate, kMaxEstimate);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _title.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      TodoDraft(
        title: title,
        notes: _notes.text.trim(),
        priority: _selectedPriority,
        estimate: _estimate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color label = GlassTheme.of(context).legibility().label;
    final InputDecorationTheme fields = InputDecorationTheme(
      filled: true,
      fillColor: label.withValues(alpha: 0.08),
      hintStyle: TextStyle(color: label.withValues(alpha: 0.45)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          GlassConcentric.radius(kGlassSheetRadius, _kSheetPadding),
        ),
        borderSide: BorderSide.none,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: label),
        child: IconTheme.merge(
          data: IconThemeData(color: label),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _kSheetPadding,
              8,
              _kSheetPadding,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(inputDecorationTheme: fields),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    widget.heading,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const ValueKey<String>('task-title-field'),
                    controller: _title,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'What needs doing?',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notes,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Notes (optional)',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Estimate: ${pomodoroLabel(_estimate)}'),
                      ),
                      GlassStepper(
                        key: const ValueKey<String>('estimate-stepper'),
                        value: _estimate.toDouble(),
                        min: kMinEstimate.toDouble(),
                        max: kMaxEstimate.toDouble(),
                        semanticLabel: 'Estimate in pomodoros',
                        onChanged: (double value) =>
                            setState(() => _estimate = value.round()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      const Text('Priority'),
                      const SizedBox(width: 12),
                      GlassGroup(
                        // Edge to edge: the selected 26 px blob sits 12 px from
                        // a 14 px neighbour (6 between the cells, 6 of
                        // centring), so 14 fuses those and keeps two small
                        // blobs (18 apart) separate.
                        spacing: 14,
                        finish: GlassFinish.clear,
                        labelled: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            for (final TodoPriority priority
                                in TodoPriority.values) ...<Widget>[
                              if (priority != TodoPriority.low)
                                const SizedBox(width: 6),
                              _PriorityBlob(
                                priority: priority,
                                selected: priority == _selectedPriority,
                                onTap: () => setState(
                                  () => _priority = _valueOf(priority),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('${_selectedPriority.label} priority'),
                    ],
                  ),
                  GlassSlider(
                    value: _priority,
                    divisions: 2,
                    onChanged: (double value) =>
                        setState(() => _priority = value),
                    semanticLabel: 'Task priority',
                    activeColor: const Color(0xFFFF9F0A),
                  ),
                  const SizedBox(height: 14),
                  GlassButton(
                    onPressed: _title.text.trim().isEmpty ? null : _submit,
                    child: Text(widget.submitLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBlob extends StatelessWidget {
  const _PriorityBlob({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TodoPriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: ValueKey<String>('priority-blob-${priority.name}'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Semantics(
      button: true,
      selected: selected,
      label: '${priority.label} priority',
      child: SizedBox.square(
        dimension: 26,
        child: Center(
          child: SizedBox.square(
            dimension: selected ? 26 : 14,
            child: const GlassSurface(
              borderRadius: kGlassCapsule,
              labelled: false,
            ),
          ),
        ),
      ),
    ),
  );
}

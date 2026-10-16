import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_item.dart';

class TodoDraft {
  const TodoDraft({
    required this.title,
    required this.notes,
    required this.priority,
  });

  final String title;
  final String notes;
  final TodoPriority priority;
}

class TodoEditorSheet extends StatefulWidget {
  const TodoEditorSheet({
    this.heading = 'New task',
    this.submitLabel = 'Add task',
    this.initialTitle = '',
    this.initialNotes = '',
    this.initialPriority = TodoPriority.medium,
    super.key,
  });

  final String heading;
  final String submitLabel;
  final String initialTitle;
  final String initialNotes;
  final TodoPriority initialPriority;

  @override
  State<TodoEditorSheet> createState() => _TodoEditorSheetState();
}

class _TodoEditorSheetState extends State<TodoEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late double _priority;

  TodoPriority get _selectedPriority => switch (_priority) {
    < 0.34 => TodoPriority.low,
    < 0.67 => TodoPriority.medium,
    _ => TodoPriority.high,
  };

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _notes = TextEditingController(text: widget.initialNotes);
    _priority = switch (widget.initialPriority) {
      TodoPriority.low => 0.15,
      TodoPriority.medium => 0.5,
      TodoPriority.high => 0.85,
    };
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
        borderRadius: BorderRadius.circular(18),
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
              20,
              8,
              20,
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
                      const Icon(Icons.flag_outlined, size: 20),
                      const SizedBox(width: 8),
                      const Text('Priority'),
                      const Spacer(),
                      Text('${_selectedPriority.label} priority'),
                    ],
                  ),
                  GlassSlider(
                    value: _priority,
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

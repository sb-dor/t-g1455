import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_editor_sheet.dart';
import 'package:t_g1455/todo_item.dart';

const double _kClosedSize = 56;
const double _kPanelWidth = 300;
const BorderRadius _kPanelRadius = BorderRadius.all(Radius.circular(28));

/// The floating "+" that morphs into a quick-add panel.
class QuickAddMorph extends StatefulWidget {
  const QuickAddMorph({required this.controller, super.key});

  final TodoController controller;

  @override
  State<QuickAddMorph> createState() => _QuickAddMorphState();
}

class _QuickAddMorphState extends State<QuickAddMorph> {
  final TextEditingController _title = TextEditingController();
  bool _open = false;
  TodoPriority _priority = TodoPriority.medium;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _setOpen(bool open) => setState(() => _open = open);

  void _submit() {
    final String title = _title.text.trim();
    if (title.isEmpty) return;
    widget.controller.addTask(title: title, priority: _priority);
    _reset();
  }

  void _reset() {
    _title.clear();
    setState(() {
      _priority = TodoPriority.medium;
      _open = false;
    });
  }

  Future<void> _openDetails() async {
    final String title = _title.text;
    final TodoPriority priority = _priority;
    _reset();
    final TodoDraft? draft = await showTodoEditor(
      context,
      initialTitle: title,
      initialPriority: priority,
    );
    if (draft == null) return;
    widget.controller.addTask(
      title: draft.title,
      notes: draft.notes,
      priority: draft.priority,
      estimate: draft.estimate,
    );
  }

  Widget _buildClosed() => Semantics(
    key: const ValueKey<String>('closed'),
    button: true,
    label: 'Add task',
    child: GestureDetector(
      key: const ValueKey<String>('quick-add-button'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _setOpen(true),
      child: const SizedBox.square(
        dimension: _kClosedSize,
        child: Icon(Icons.add),
      ),
    ),
  );

  Widget _buildPanel() => Padding(
    key: const ValueKey<String>('panel'),
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: _kPanelWidth - 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GlassTextField(
            key: const ValueKey<String>('quick-add-field'),
            controller: _title,
            placeholder: 'New task',
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          GlassSegmentedControl(
            segments: <Widget>[
              for (final TodoPriority priority in TodoPriority.values)
                Text(priority.label),
            ],
            selectedIndex: _priority.index,
            onSelected: (int index) =>
                setState(() => _priority = TodoPriority.values[index]),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  key: const ValueKey<String>('quick-add-details'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _openDetails,
                  child: const Text('More details'),
                ),
              ),
              GestureDetector(
                key: const ValueKey<String>('quick-add-close'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _setOpen(false),
                child: const SizedBox.square(
                  dimension: 44,
                  child: Icon(Icons.close),
                ),
              ),
              const SizedBox(width: 4),
              GlassButton(
                key: const ValueKey<String>('quick-add-submit'),
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: GlassMorph(
      alignment: Alignment.bottomRight,
      borderRadius: _open ? _kPanelRadius : kGlassCapsule,
      child: _open ? _buildPanel() : _buildClosed(),
    ),
  );
}

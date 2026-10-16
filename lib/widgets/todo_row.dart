import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_editor_sheet.dart';
import 'package:t_g1455/todo_item.dart';

class TodoRow extends StatelessWidget {
  const TodoRow({
    required this.item,
    required this.controller,
    this.glass = false,
    super.key,
  });

  final TodoItem item;
  final TodoController controller;
  final bool glass;

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (BuildContext context) => GlassAlert(
        title: Text('Delete "${item.title}"?', textAlign: TextAlign.center),
        message: const Text(
          'This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actions: <GlassAlertAction>[
          GlassAlertAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          GlassAlertAction(
            label: 'Delete',
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.deleteTask(item.id);
  }

  Future<void> _openEditor(BuildContext context) async {
    final TodoDraft? draft = await showGlassSheet<TodoDraft>(
      context: context,
      barrierLabel: 'Close task editor',
      builder: (BuildContext context) => TodoEditorSheet(
        heading: 'Edit task',
        submitLabel: 'Save changes',
        initialTitle: item.title,
        initialNotes: item.notes,
        initialPriority: item.priority,
      ),
    );
    if (draft == null) return;
    controller.updateTask(
      item.id,
      title: draft.title,
      notes: draft.notes,
      priority: draft.priority,
      estimate: item.estimate,
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xCC1A1D29),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          GlassSwitch(
            key: ValueKey<String>('todo-toggle-${item.id}'),
            value: item.isCompleted,
            onChanged: (bool value) => controller.setCompleted(item.id, value),
            semanticLabel: 'Complete ${item.title}',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              key: ValueKey<String>('edit-task-${item.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _openEditor(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: switch (item.priority) {
                          TodoPriority.low => const Color(0xFF43D9AD),
                          TodoPriority.medium => const Color(0xFFFFCC66),
                          TodoPriority.high => const Color(0xFFFF6B7A),
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCompleted
                                ? const Color(0x99FFFFFF)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.notes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.notes,
                      style: const TextStyle(color: Color(0xB3FFFFFF)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GlassMenuAnchor(
            width: 210,
            barrierLabel: 'Close task actions',
            items: <GlassMenuItem>[
              GlassMenuItem(
                label: 'Delete',
                icon: const Icon(Icons.delete_outline, size: 20),
                isDestructive: true,
                onPressed: () => _confirmDelete(context),
              ),
            ],
            builder: (BuildContext context, GlassMenuController menu) =>
                Semantics(
                  button: true,
                  label: 'Actions for ${item.title}',
                  child: GestureDetector(
                    key: ValueKey<String>('task-menu-${item.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: menu.open,
                    child: const SizedBox.square(
                      dimension: 44,
                      child: Icon(Icons.more_horiz),
                    ),
                  ),
                ),
          ),
        ],
      ),
    ),
  );
}

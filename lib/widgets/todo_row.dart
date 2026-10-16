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
    final TodoDraft? draft = await showTodoEditor(
      context,
      heading: 'Edit task',
      submitLabel: 'Save changes',
      initialTitle: item.title,
      initialNotes: item.notes,
      initialPriority: item.priority,
      initialEstimate: item.estimate,
    );
    if (draft == null) return;
    controller.updateTask(
      item.id,
      title: draft.title,
      notes: draft.notes,
      priority: draft.priority,
      estimate: draft.estimate,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Secondary ink for the plain row: white on the dark page, near-black on
    // the light one, at the same alphas as before.
    final bool light = Theme.of(context).brightness == Brightness.light;
    final Color ink = light ? const Color(0xFF1B1B24) : const Color(0xFFFFFFFF);
    final Widget content = Row(
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
                          color: item.isCompleted && !glass
                              ? ink.withAlpha(0x99)
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
                    style: glass ? null : TextStyle(color: ink.withAlpha(0xB3)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  pomodoroLabel(item.estimate),
                  style: glass ? null : TextStyle(color: ink.withAlpha(0x99)),
                ),
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
    );

    if (glass) {
      return GlassBackdrop.live(
        child: GlassCard(padding: const EdgeInsets.all(16), child: content),
      );
    }
    return GlassBackdrop.live(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: light ? const Color(0xCCFFFFFF) : const Color(0xCC1A1D29),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ink.withValues(alpha: 0.08)),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: content),
      ),
    );
  }
}

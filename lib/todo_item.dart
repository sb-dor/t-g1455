enum TodoPriority { low, medium, high }

extension TodoPriorityLabel on TodoPriority {
  String get label => switch (this) {
    TodoPriority.low => 'Low',
    TodoPriority.medium => 'Medium',
    TodoPriority.high => 'High',
  };
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.notes = '',
    this.priority = TodoPriority.medium,
    this.isCompleted = false,
  });

  final int id;
  final String title;
  final String notes;
  final TodoPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  TodoItem copyWith({
    String? title,
    String? notes,
    TodoPriority? priority,
    bool? isCompleted,
  }) => TodoItem(
    id: id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt,
  );
}

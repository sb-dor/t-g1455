enum TodoPriority { low, medium, high }

const int kMinEstimate = 1;
const int kMaxEstimate = 10;

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
    this.estimate = 1,
  });

  final int id;
  final String title;
  final String notes;
  final TodoPriority priority;
  final bool isCompleted;
  final int estimate;
  final DateTime createdAt;

  TodoItem copyWith({
    String? title,
    String? notes,
    TodoPriority? priority,
    bool? isCompleted,
    int? estimate,
  }) => TodoItem(
    id: id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    priority: priority ?? this.priority,
    isCompleted: isCompleted ?? this.isCompleted,
    estimate: estimate ?? this.estimate,
    createdAt: createdAt,
  );
}

import 'package:flutter/foundation.dart';
import 'package:t_g1455/todo_item.dart';

enum TodoView { all, open, done }

enum TodoSort { newest, title }

class TodoController extends ChangeNotifier {
  final List<TodoItem> _items = <TodoItem>[];
  int _nextId = 1;
  TodoView _view = TodoView.all;
  TodoSort _sort = TodoSort.newest;
  String _query = '';
  bool _showCompleted = true;

  List<TodoItem> get items => List<TodoItem>.unmodifiable(_items);
  TodoView get view => _view;
  TodoSort get sort => _sort;
  String get query => _query;
  bool get showCompleted => _showCompleted;
  int get completedCount =>
      _items.where((TodoItem item) => item.isCompleted).length;

  List<TodoItem> get visibleItems {
    final List<TodoItem> visible = _items.where((TodoItem item) {
      final bool inView = switch (_view) {
        TodoView.all => _showCompleted || !item.isCompleted,
        TodoView.open => !item.isCompleted,
        TodoView.done => item.isCompleted,
      };
      if (!inView) return false;
      final String query = _query.trim().toLowerCase();
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);
    }).toList();
    switch (_sort) {
      case TodoSort.newest:
        visible.sort((TodoItem a, TodoItem b) => b.id.compareTo(a.id));
      case TodoSort.title:
        visible.sort(
          (TodoItem a, TodoItem b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return List<TodoItem>.unmodifiable(visible);
  }

  void addTask({
    required String title,
    String notes = '',
    TodoPriority priority = TodoPriority.medium,
  }) {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    _items.add(
      TodoItem(
        id: _nextId++,
        title: cleanTitle,
        notes: notes.trim(),
        priority: priority,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void setCompleted(int id, bool isCompleted) {
    final int index = _items.indexWhere((TodoItem item) => item.id == id);
    if (index == -1 || _items[index].isCompleted == isCompleted) return;
    _items[index] = _items[index].copyWith(isCompleted: isCompleted);
    notifyListeners();
  }

  void selectView(TodoView view) {
    if (_view == view) return;
    _view = view;
    notifyListeners();
  }

  void setQuery(String query) {
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  void selectSort(TodoSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void setShowCompleted(bool showCompleted) {
    if (_showCompleted == showCompleted) return;
    _showCompleted = showCompleted;
    notifyListeners();
  }

  void deleteTask(int id) {
    final int before = _items.length;
    _items.removeWhere((TodoItem item) => item.id == id);
    if (_items.length != before) notifyListeners();
  }

  void updateTask(
    int id, {
    required String title,
    required String notes,
    required TodoPriority priority,
  }) {
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final int index = _items.indexWhere((TodoItem item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      title: cleanTitle,
      notes: notes.trim(),
      priority: priority,
    );
    notifyListeners();
  }

  void clearCompleted() {
    final int before = _items.length;
    _items.removeWhere((TodoItem item) => item.isCompleted);
    if (_items.length != before) notifyListeners();
  }
}

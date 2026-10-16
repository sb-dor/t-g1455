import 'package:flutter_test/flutter_test.dart';
import 'package:t_g1455/todo_controller.dart';
import 'package:t_g1455/todo_item.dart';

void main() {
  test('addTask stores the estimate', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'A', estimate: 3);
    expect(controller.items.single.estimate, 3);
  });

  test('estimate is clamped to 1–10', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'Low', estimate: 0);
    controller.addTask(title: 'High', estimate: 42);
    expect(controller.items[0].estimate, kMinEstimate);
    expect(controller.items[1].estimate, kMaxEstimate);

    controller.updateTask(
      controller.items[0].id,
      title: 'Low',
      notes: '',
      priority: TodoPriority.medium,
      estimate: -5,
    );
    expect(controller.items[0].estimate, kMinEstimate);
  });

  test('openCount counts tasks not completed', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'A');
    controller.addTask(title: 'B');
    controller.addTask(title: 'C');
    controller.setCompleted(controller.items.first.id, true);
    expect(controller.openCount, 2);
  });

  test('nextUp follows the sort and skips completed tasks', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'Zulu');
    controller.addTask(title: 'Apple');
    expect(controller.nextUp!.title, 'Apple');

    controller.selectSort(TodoSort.title);
    expect(controller.nextUp!.title, 'Apple');

    controller.setCompleted(
      controller.items.firstWhere((TodoItem i) => i.title == 'Apple').id,
      true,
    );
    expect(controller.nextUp!.title, 'Zulu');

    controller.setCompleted(
      controller.items.firstWhere((TodoItem i) => i.title == 'Zulu').id,
      true,
    );
    expect(controller.nextUp, isNull);
  });

  test('nextUp ignores the query and the view', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'Apple');
    controller.setQuery('zzz');
    controller.selectView(TodoView.done);
    expect(controller.nextUp!.title, 'Apple');
  });

  test('completeAll completes every task and notifies once', () {
    final TodoController controller = TodoController();
    controller.addTask(title: 'A');
    controller.addTask(title: 'B');
    int notifications = 0;
    controller.addListener(() => notifications++);

    controller.completeAll();
    expect(controller.completedCount, 2);
    expect(notifications, 1);

    controller.completeAll();
    expect(notifications, 1);
  });
}

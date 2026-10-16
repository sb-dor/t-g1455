// Simulator-pass harness, not a bug repro: runs the todo app with seeded tasks
// and Lab settings preset from dart-defines, so a state can be screenshotted
// without driving it by touch.
//
//   flutter run -t repro/sim_pass.dart --dart-define=FINISH=frosted \
//     --dart-define=REDUCE=true --dart-define=CHEAP=true \
//     --dart-define=ADAPTIVE=false --dart-define=CONTRAST=true \
//     --dart-define=ROWS=true --dart-define=OUTLINES=true --dart-define=TASKS=12
import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';
import 'package:t_g1455/lab/lab_settings.dart';
import 'package:t_g1455/main.dart';
import 'package:t_g1455/todo_controller.dart';

const String kFinish = String.fromEnvironment('FINISH', defaultValue: 'auto');
const int kTasks = int.fromEnvironment('TASKS', defaultValue: 6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassHost.precache();
  final TodoController tasks = TodoController();
  for (int i = 1; i <= kTasks; i++) {
    tasks.addTask(title: 'Task $i');
  }
  if (kTasks >= 2) {
    tasks
      ..setCompleted(1, true)
      ..setCompleted(2, true);
  }
  final LabSettings lab = LabSettings()
    ..setFinish(LabFinish.values.byName(kFinish))
    ..setReduceTransparency(const bool.fromEnvironment('REDUCE'))
    ..setCheapCeiling(const bool.fromEnvironment('CHEAP'))
    ..setAdaptive(const bool.fromEnvironment('ADAPTIVE', defaultValue: true))
    ..setHighContrast(const bool.fromEnvironment('CONTRAST'))
    ..setGlassRows(const bool.fromEnvironment('ROWS'))
    ..setRipple(const bool.fromEnvironment('RIPPLE'));
  runApp(App(controller: tasks, lab: lab));
  if (const bool.fromEnvironment('OUTLINES')) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => lab.setDebugOutlines(true),
    );
  }
}

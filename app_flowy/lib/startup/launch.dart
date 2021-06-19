import 'package:app_flowy/startup/startup.dart';
import 'package:get_it/get_it.dart';

class LaunchContext {
  GetIt getIt;
  IntegrationEnv env;
  LaunchContext(this.getIt, this.env);
}

enum LaunchTaskType {
  dataProcessing,
  appLauncher,
}

/// The interface of an app launch task, which will trigger
/// some nonresident indispensable task in app launching task.
abstract class LaunchTask {
  LaunchTaskType get type => LaunchTaskType.dataProcessing;
  void initialize(LaunchContext context);
}

class AppLauncher {
  List<LaunchTask> tasks;
  IntegrationEnv env;
  GetIt getIt;

  AppLauncher(this.env, this.getIt) : tasks = List.from([]);

  void addTask(LaunchTask task) {
    tasks.add(task);
  }

  void launch() {
    final context = LaunchContext(getIt, env);
    for (var task in tasks) {
      task.initialize(context);
    }
  }
}
//test git hooks

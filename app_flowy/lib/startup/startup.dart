import 'package:app_flowy/startup/launch.dart';
import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'deps_inject/prelude.dart';

final getIt = GetIt.instance;
enum IntegrationEnv {
  dev,
  pro,
}

abstract class EntryPoint {
  Widget create();
}

class System {
  static void run(EntryPoint f) {
    // Specify the evn
    const env = IntegrationEnv.dev;

    // Config the deps graph
    getIt.registerFactory<EntryPoint>(() => f);

    resolveDependencies(env);

    // add task
    getIt<AppLauncher>().addTask(RustSDKInitTask());
    getIt<AppLauncher>().addTask(AppWidgetTask());

    // execute the tasks
    getIt<AppLauncher>().launch();
  }
}

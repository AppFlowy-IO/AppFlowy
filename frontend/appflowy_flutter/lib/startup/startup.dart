import 'dart:io';

import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'deps_resolver.dart';
import 'entry_point.dart';
import 'launch_configuration.dart';
import 'plugin/plugin.dart';
import 'tasks/prelude.dart';

final getIt = GetIt.instance;

abstract class EntryPoint {
  Widget create(LaunchConfiguration config);
}

class FlowyRunnerContext {
  final Directory applicationDataDirectory;

  FlowyRunnerContext({required this.applicationDataDirectory});
}

Future<void> runAppFlowy() async {
  await FlowyRunner.run(
    FlowyApp(),
    integrationMode(),
  );
}

class FlowyRunner {
  static Future<FlowyRunnerContext> run(
    EntryPoint f,
    IntegrationMode mode, {
    LaunchConfiguration config = const LaunchConfiguration(
      autoRegistrationSupported: false,
    ),
  }) async {
    // Clear all the states in case of rebuilding.
    await getIt.reset();

    // Specify the env
    initGetIt(getIt, mode, f, config);

    final applicationDataDirectory =
        await getIt<ApplicationDataStorage>().getPath().then(
              (value) => Directory(value),
            );

    // add task
    final launcher = getIt<AppLauncher>();
    launcher.addTasks(
      [
        // this task should be first task, for handling platform errors.
        // don't catch errors in test mode
        if (!mode.isUnitTest) const PlatformErrorCatcherTask(),
        // localization
        const InitLocalizationTask(),
        // init the app window
        const InitAppWindowTask(),
        // Init Rust SDK
        InitRustSDKTask(directory: applicationDataDirectory),
        // Load Plugins, like document, grid ...
        const PluginLoadTask(),

        // init the app widget
        // ignore in test mode
        if (!mode.isUnitTest) ...[
          const HotKeyTask(),
          InitSupabaseTask(),
          const InitAppWidgetTask(),
          const InitPlatformServiceTask()
        ],
      ],
    );
    await launcher.launch(); // execute the tasks

    return FlowyRunnerContext(
      applicationDataDirectory: applicationDataDirectory,
    );
  }
}

Future<void> initGetIt(
  GetIt getIt,
  IntegrationMode mode,
  EntryPoint f,
  LaunchConfiguration config,
) async {
  getIt.registerFactory<EntryPoint>(() => f);
  getIt.registerLazySingleton<FlowySDK>(() {
    return FlowySDK();
  });
  getIt.registerLazySingleton<AppLauncher>(
    () => AppLauncher(
      context: LaunchContext(
        getIt,
        mode,
        config,
      ),
    ),
  );
  getIt.registerSingleton<PluginSandbox>(PluginSandbox());

  await DependencyResolver.resolve(getIt, mode);
}

class LaunchContext {
  GetIt getIt;
  IntegrationMode env;
  LaunchConfiguration config;
  LaunchContext(this.getIt, this.env, this.config);
}

enum LaunchTaskType {
  dataProcessing,
  appLauncher,
}

/// The interface of an app launch task, which will trigger
/// some nonresident indispensable task in app launching task.
abstract class LaunchTask {
  const LaunchTask();

  LaunchTaskType get type => LaunchTaskType.dataProcessing;

  Future<void> initialize(LaunchContext context);
}

class AppLauncher {
  AppLauncher({
    required this.context,
  });

  final LaunchContext context;
  final List<LaunchTask> tasks = [];

  void addTask(LaunchTask task) {
    tasks.add(task);
  }

  void addTasks(Iterable<LaunchTask> tasks) {
    this.tasks.addAll(tasks);
  }

  Future<void> launch() async {
    for (final task in tasks) {
      await task.initialize(context);
    }
  }
}

enum IntegrationMode {
  develop,
  release,
  unitTest,
  integrationTest;

  // test mode
  bool get isTest => isUnitTest || isIntegrationTest;
  bool get isUnitTest => this == IntegrationMode.unitTest;
  bool get isIntegrationTest => this == IntegrationMode.integrationTest;

  // release mode
  bool get isRelease => this == IntegrationMode.release;

  // develop mode
  bool get isDevelop => this == IntegrationMode.develop;
}

IntegrationMode integrationMode() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return IntegrationMode.unitTest;
  }

  if (kReleaseMode) {
    return IntegrationMode.release;
  }

  return IntegrationMode.develop;
}

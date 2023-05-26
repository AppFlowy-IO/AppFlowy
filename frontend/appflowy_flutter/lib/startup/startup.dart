import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'deps_resolver.dart';
import 'launch_configuration.dart';
import 'plugin/plugin.dart';
import 'tasks/prelude.dart';

final getIt = GetIt.instance;

abstract class EntryPoint {
  Widget create(LaunchConfiguration config);
}

class FlowyRunner {
  static Future<void> run(
    EntryPoint f, {
    LaunchConfiguration config = const LaunchConfiguration(
      autoRegistrationSupported: false,
    ),
  }) async {
    // Clear all the states in case of rebuilding.
    await getIt.reset();

    // Specify the env
    final env = integrationEnv();
    initGetIt(getIt, env, f, config);

    final directory = await getIt<LocalFileStorage>()
        .getPath()
        .then((value) => Directory(value));

    // final directory = await appFlowyDocumentDirectory();

    // add task
    final launcher = getIt<AppLauncher>();
    launcher.addTasks(
      [
        // handle platform errors.
        const PlatformErrorCatcherTask(),
        // localization
        const InitLocalizationTask(),
        // init the app window
        const InitAppWindowTask(),
        // Init Rust SDK
        InitRustSDKTask(directory: directory),
        // Load Plugins, like document, grid ...
        const PluginLoadTask(),

        // init the app widget
        // ignore in test mode
        if (!env.isTest()) ...[
          const HotKeyTask(),
          InitSupabaseTask(
            url: Env.supabaseUrl,
            anonKey: Env.supabaseAnonKey,
            key: Env.supabaseKey,
            jwtSecret: Env.supabaseJwtSecret,
            collabTable: Env.supabaseCollabTable,
          ),
          const InitAppWidgetTask(),
          const InitPlatformServiceTask()
        ],
      ],
    );
    await launcher.launch(); // execute the tasks
  }
}

Future<void> initGetIt(
  GetIt getIt,
  IntegrationMode env,
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
        env,
        config,
      ),
    ),
  );
  getIt.registerSingleton<PluginSandbox>(PluginSandbox());

  await DependencyResolver.resolve(getIt);
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
  test,
}

extension IntegrationEnvExt on IntegrationMode {
  bool isTest() {
    return this == IntegrationMode.test;
  }
}

IntegrationMode integrationEnv() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return IntegrationMode.test;
  }

  if (kReleaseMode) {
    return IntegrationMode.release;
  }

  return IntegrationMode.develop;
}

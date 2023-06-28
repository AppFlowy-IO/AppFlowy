import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:appflowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

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

    final directory = await directoryFromMode(mode);

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
        if (!mode.isUnitTest()) ...[
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

Future<Directory> directoryFromMode(IntegrationMode mode) async {
  // Only use the temporary directory in test mode.
  if (mode.isTest() && !kReleaseMode) {
    final dir = await getTemporaryDirectory();

    // Use a random uuid to avoid conflict.
    final path = '${dir.path}/appflowy_integration_test/${uuid()}';
    return Directory(path).create(recursive: true);
  }

  return getIt<ApplicationDataStorage>().getPath().then(
        (value) => Directory(value),
      );
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
  unitTest,
  integrationTest,
}

extension IntegrationEnvExt on IntegrationMode {
  bool isUnitTest() {
    return this == IntegrationMode.unitTest;
  }

  bool isIntegrationTest() {
    return this == IntegrationMode.integrationTest;
  }

  bool isTest() {
    return isUnitTest() || isIntegrationTest();
  }

  bool isRelease() {
    return this == IntegrationMode.release;
  }

  bool isDevelop() {
    return this == IntegrationMode.develop;
  }
}

IntegrationMode integrationEnv() {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return IntegrationMode.unitTest;
  }

  if (kReleaseMode) {
    return IntegrationMode.release;
  }

  return IntegrationMode.develop;
}

import 'dart:io';

import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../workspace/application/settings/settings_location_cubit.dart';
import 'deps_resolver.dart';
import 'launch_configuration.dart';
import 'plugin/plugin.dart';
import 'tasks/prelude.dart';

// [[diagram: flowy startup flow]]
//                   ┌──────────┐
//                   │ FlowyApp │
//                   └──────────┘
//                         │  impl
//                         ▼
// ┌────────┐  1.run ┌──────────┐
// │ System │───┬───▶│EntryPoint│
// └────────┘   │    └──────────┘         ┌─────────────────┐
//              │                    ┌──▶ │ RustSDKInitTask │
//              │    ┌───────────┐   │    └─────────────────┘
//              └──▶ │AppLauncher│───┤
//        2.launch   └───────────┘   │    ┌─────────────┐         ┌──────────────────┐      ┌───────────────┐
//                                   └───▶│AppWidgetTask│────────▶│ApplicationWidget │─────▶│ SplashScreen  │
//                                        └─────────────┘         └──────────────────┘      └───────────────┘
//
//                                                 3.build MaterialApp
final getIt = GetIt.instance;

abstract class EntryPoint {
  Widget create(final LaunchConfiguration config);
}

class FlowyRunner {
  static Future<void> run(
    final EntryPoint f, {
    final LaunchConfiguration config =
        const LaunchConfiguration(autoRegistrationSupported: false),
  }) async {
    // Clear all the states in case of rebuilding.
    await getIt.reset();

    // Specify the env
    final env = integrationEnv();
    initGetIt(getIt, env, f, config);

    final directory = getIt<SettingsLocationCubit>()
        .fetchLocation()
        .then((final value) => Directory(value));

    // add task
    getIt<AppLauncher>().addTask(InitRustSDKTask(directory: directory));
    getIt<AppLauncher>().addTask(PluginLoadTask());

    if (!env.isTest()) {
      getIt<AppLauncher>().addTask(InitAppWidgetTask());
      getIt<AppLauncher>().addTask(InitPlatformServiceTask());
    }

    // execute the tasks
    await getIt<AppLauncher>().launch();
  }
}

Future<void> initGetIt(
  final GetIt getIt,
  final IntegrationMode env,
  final EntryPoint f,
  final LaunchConfiguration config,
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
  LaunchTaskType get type => LaunchTaskType.dataProcessing;
  Future<void> initialize(final LaunchContext context);
}

class AppLauncher {
  List<LaunchTask> tasks;

  final LaunchContext context;

  AppLauncher({required this.context}) : tasks = List.from([]);

  void addTask(final LaunchTask task) {
    tasks.add(task);
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

import 'dart:io';

import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:app_flowy/startup/deps_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flowy_sdk/flowy_sdk.dart';

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
//                                                 3.build MeterialApp
final getIt = GetIt.instance;

abstract class EntryPoint {
  Widget create();
}

class FlowyRunner {
  static Future<void> run(EntryPoint f) async {
    // Specify the env
    final env = integrationEnv();
    initGetIt(getIt, env, f);

    // add task
    getIt<AppLauncher>().addTask(InitRustSDKTask());

    if (!env.isTest()) {
      getIt<AppLauncher>().addTask(PluginLoadTask());
      getIt<AppLauncher>().addTask(InitAppWidgetTask());
      getIt<AppLauncher>().addTask(InitPlatformServiceTask());
    }

    // execute the tasks
    getIt<AppLauncher>().launch();
  }
}

Future<void> initGetIt(
  GetIt getIt,
  IntegrationMode env,
  EntryPoint f,
) async {
  getIt.registerFactory<EntryPoint>(() => f);
  getIt.registerLazySingleton<FlowySDK>(() => const FlowySDK());
  getIt.registerLazySingleton<AppLauncher>(() => AppLauncher(env, getIt));
  getIt.registerSingleton<PluginSandbox>(PluginSandbox());

  await DependencyResolver.resolve(getIt);
}

class LaunchContext {
  GetIt getIt;
  IntegrationMode env;
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
  Future<void> initialize(LaunchContext context);
}

class AppLauncher {
  List<LaunchTask> tasks;
  IntegrationMode env;
  GetIt getIt;

  AppLauncher(this.env, this.getIt) : tasks = List.from([]);

  void addTask(LaunchTask task) {
    tasks.add(task);
  }

  Future<void> launch() async {
    final context = LaunchContext(getIt, env);
    for (var task in tasks) {
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

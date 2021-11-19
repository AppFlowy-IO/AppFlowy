import 'package:app_flowy/startup/launcher.dart';
import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app_flowy/workspace/infrastructure/deps_resolver.dart';
import 'package:app_flowy/user/infrastructure/deps_resolver.dart';
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
enum IntegrationEnv {
  dev,
  pro,
}

abstract class EntryPoint {
  Widget create();
}

class System {
  static void run(EntryPoint f) {
    // Specify the env
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

void resolveDependencies(IntegrationEnv env) => initGetIt(getIt, env);

Future<void> initGetIt(
  GetIt getIt,
  IntegrationEnv env,
) async {
  getIt.registerLazySingleton<FlowySDK>(() => const FlowySDK());
  getIt.registerLazySingleton<AppLauncher>(() => AppLauncher(env, getIt));

  await UserDepsResolver.resolve(getIt);
  await HomeDepsResolver.resolve(getIt);
}

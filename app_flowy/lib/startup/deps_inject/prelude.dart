import 'package:app_flowy/workspace/infrastructure/deps_resolver.dart';
import 'package:app_flowy/startup/launch.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/infrastructure/deps_resolver.dart';
import 'package:app_flowy/welcome/infrastructure/deps_resolver.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:get_it/get_it.dart';

void resolveDependencies(IntegrationEnv env) => initGetIt(getIt, env);

Future<void> initGetIt(
  GetIt getIt,
  IntegrationEnv env,
) async {
  getIt.registerLazySingleton<FlowySDK>(() => const FlowySDK());
  getIt.registerLazySingleton<AppLauncher>(() => AppLauncher(env, getIt));

  await WelcomeDepsResolver.resolve(getIt);
  await UserDepsResolver.resolve(getIt);
  await HomeDepsResolver.resolve(getIt);
}

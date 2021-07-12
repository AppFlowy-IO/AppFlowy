import 'package:app_flowy/startup/launch.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/welcome/infrastructure/interface_impl.dart';
import 'package:flowy_sdk/flowy_sdk.dart';
import 'package:get_it/get_it.dart';

void resolveDependencies(IntegrationEnv env) => initGetIt(getIt, env);

Future<void> initGetIt(
  GetIt getIt,
  IntegrationEnv env,
) async {
  getIt.registerLazySingleton<FlowySDK>(() => const FlowySDK());
  getIt.registerLazySingleton<AppLauncher>(() => AppLauncher(env, getIt));

  await Welcome.dependencyResolved(getIt);
}

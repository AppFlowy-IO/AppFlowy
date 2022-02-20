import 'package:app_flowy/user/application/sign_in_bloc.dart';
import 'package:app_flowy/user/application/sign_up_bloc.dart';
import 'package:app_flowy/user/application/splash_bloc.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:app_flowy/user/infrastructure/router.dart';
import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:get_it/get_it.dart';

import 'network_monitor.dart';

class UserDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactory<AuthRepository>(() => AuthRepository());

    //Interface implementation
    getIt.registerFactory<AuthRouter>(() => AuthRouter());

    //Bloc
    getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<AuthRepository>()));
    getIt.registerFactory<SignUpBloc>(() => SignUpBloc(getIt<AuthRepository>()));

    getIt.registerFactory<SplashRoute>(() => SplashRoute());
    getIt.registerFactory<HomeBloc>(() => HomeBloc());
    getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());
    getIt.registerFactory<SplashBloc>(() => SplashBloc());
    getIt.registerLazySingleton<NetworkListener>(() => NetworkListener());
  }
}

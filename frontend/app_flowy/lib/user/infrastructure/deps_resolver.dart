import 'package:app_flowy/user/application/sign_in_bloc.dart';
import 'package:app_flowy/user/application/sign_up_bloc.dart';
import 'package:app_flowy/user/application/splash_bloc.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/domain/i_splash.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:app_flowy/user/infrastructure/i_auth_impl.dart';
import 'package:app_flowy/user/infrastructure/i_splash_impl.dart';
import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_listen_bloc.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:app_flowy/workspace/infrastructure/i_user_impl.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:get_it/get_it.dart';

import 'network_monitor.dart';

class UserDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactory<AuthRepository>(() => AuthRepository());

    //Interface implementation
    getIt.registerFactory<IAuth>(() => AuthImpl(repo: getIt<AuthRepository>()));
    getIt.registerFactory<IAuthRouter>(() => AuthRouterImpl());

    //Bloc
    getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<IAuth>()));
    getIt.registerFactory<SignUpBloc>(() => SignUpBloc(getIt<IAuth>()));

    getIt.registerFactory<ISplashUser>(() => SplashUserImpl());
    getIt.registerFactory<ISplashRoute>(() => SplashRoute());
    getIt.registerFactory<HomeBloc>(() => HomeBloc());
    getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());
    getIt.registerFactory<SplashBloc>(() => SplashBloc(getIt<ISplashUser>()));

    getIt.registerFactoryParam<HomeListenBloc, UserProfile, void>(
      (user, _) => HomeListenBloc(
        getIt<IUserListener>(param1: user),
      ),
    );

    getIt.registerLazySingleton<NetworkMonitor>(() => NetworkMonitor());
  }
}

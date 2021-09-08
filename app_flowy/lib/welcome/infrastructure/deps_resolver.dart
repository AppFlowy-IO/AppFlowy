import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/welcome/application/splash_bloc.dart';
import 'package:app_flowy/welcome/infrastructure/i_splash_impl.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_auth_bloc.dart';
import 'package:app_flowy/workspace/domain/i_user.dart';
import 'package:app_flowy/workspace/infrastructure/i_user_impl.dart';
import 'package:get_it/get_it.dart';

class WelcomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactory<ISplashUser>(() => SplashUserImpl());
    getIt.registerFactory<ISplashRoute>(() => SplashRoute());
    getIt.registerFactory<HomeBloc>(() => HomeBloc());
    getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());
    getIt.registerFactory<SplashBloc>(() => SplashBloc(getIt<ISplashUser>()));

    getIt.registerFactoryParam<HomeAuthBloc, UserProfile, void>(
      (user, _) => HomeAuthBloc(
        getIt<IUserWatch>(param1: user),
      ),
    );
  }
}

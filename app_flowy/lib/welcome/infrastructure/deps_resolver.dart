import 'package:app_flowy/workspace/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/welcome/application/splash_bloc.dart';
import 'package:app_flowy/welcome/infrastructure/i_splash_impl.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_watcher_bloc.dart';
import 'package:get_it/get_it.dart';

class WelcomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerFactory<ISplashUser>(() => SplashUserImpl());
    getIt.registerFactory<ISplashRoute>(() => SplashRoute());
    getIt.registerFactory<HomeBloc>(() => HomeBloc());
    getIt.registerFactory<HomeWatcherBloc>(() => HomeWatcherBloc());
    getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());

    getIt.registerFactory<SplashBloc>(() => SplashBloc(getIt<ISplashUser>()));
  }
}

import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/infrastructure/app_repo.dart';
import 'package:app_flowy/home/infrastructure/i_app_impl.dart';
import 'package:get_it/get_it.dart';

class HomeDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerLazySingleton<AppRepository>(() => AppRepository());

    //Interface implementation
    getIt.registerFactory<IApp>(() => IAppImpl(repo: getIt<AppRepository>()));

    //Bloc
    getIt.registerFactory<MenuBloc>(() => MenuBloc(getIt<IApp>()));
  }
}

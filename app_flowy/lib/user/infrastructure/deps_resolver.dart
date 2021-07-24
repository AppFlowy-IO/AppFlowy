import 'package:app_flowy/user/application/sign_in/sign_in_bloc.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:app_flowy/user/infrastructure/i_auth_impl.dart';
import 'package:get_it/get_it.dart';

class UserDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());

    //Interface implementation
    getIt.registerFactory<IAuth>(() => AuthImpl(repo: getIt<AuthRepository>()));

    //Bloc
    getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<IAuth>()));
  }
}

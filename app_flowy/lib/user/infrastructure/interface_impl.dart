import 'package:app_flowy/user/application/sign_in/sign_in_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/errors.pb.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:get_it/get_it.dart';

import 'package:app_flowy/user/domain/interface.dart';
import 'package:app_flowy/user/infrastructure/auth_repo.dart';

class UserDepsResolver {
  static Future<void> resolve(GetIt getIt) async {
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());

    //Interface implementation
    getIt.registerFactory<IAuth>(() => AuthImpl(repo: getIt<AuthRepository>()));

    //Bloc
    getIt.registerFactory<SignInBloc>(() => SignInBloc(getIt<IAuth>()));
  }
}

class AuthImpl extends IAuth {
  AuthRepository repo;
  AuthImpl({
    required this.repo,
  });

  @override
  Future<Either<UserDetail, UserError>> signIn(
      String? email, String? password) {
    return repo.signIn(email: email, password: password);
  }

  @override
  Future<Either<UserDetail, UserError>> signUp(
      String? name, String? password, String? email) {
    return repo.signUp(name: name, password: password, email: email);
  }
}

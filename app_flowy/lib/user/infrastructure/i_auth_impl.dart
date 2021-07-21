import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';

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

  @override
  Future<Either<Unit, UserError>> signOut() {
    return repo.signOut();
  }
}

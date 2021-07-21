import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';

class AuthRepository {
  Future<Either<UserDetail, UserError>> signIn(
      {required String? email, required String? password}) {
    //
    final request = SignInRequest.create()
      ..email = email ?? ''
      ..password = password ?? '';

    return UserEventSignIn(request).send();
  }

  Future<Either<UserDetail, UserError>> signUp(
      {required String? name,
      required String? password,
      required String? email}) {
    final request = SignUpRequest.create()
      ..email = email ?? ''
      ..name = name ?? ''
      ..password = password ?? '';

    return UserEventSignUp(request).send();
  }

  Future<Either<Unit, UserError>> signOut() {
    return UserEventSignOut().send();
  }
}

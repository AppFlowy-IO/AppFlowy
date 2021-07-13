import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';

abstract class IAuth {
  Future<Either<UserDetail, UserError>> signIn(String? email, String? password);
  Future<Either<UserDetail, UserError>> signUp(
      String? name, String? password, String? email);

  Future<Either<Unit, UserError>> signOut();
}

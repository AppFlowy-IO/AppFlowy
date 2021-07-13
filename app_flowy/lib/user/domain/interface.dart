import 'package:flowy_sdk/protobuf/errors.pb.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:dartz/dartz.dart';

abstract class IAuth {
  Future<Either<UserDetail, UserError>> signIn(String? email, String? password);
  Future<Either<UserDetail, UserError>> signUp(
      String? name, String? password, String? email);

  Future<Either<Unit, UserError>> signOut();
}

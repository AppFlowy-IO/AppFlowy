import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';

class UserRepo {
  final UserDetail user;
  UserRepo({
    required this.user,
  });

  Future<Either<UserDetail, UserError>> fetchUserDetail(
      {required String userId}) {
    return UserEventGetStatus().send();
  }
}

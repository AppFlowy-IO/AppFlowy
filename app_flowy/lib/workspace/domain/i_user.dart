import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

export 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
export 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';

abstract class IUser {
  Future<Either<Unit, WorkspaceError>> deleteWorkspace(String workspaceId);
  Future<Either<UserDetail, UserError>> fetchUserDetail(String userId);
  Future<Either<Unit, UserError>> signOut();
}

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:flutter/material.dart';

class NewUser {
  UserProfile profile;
  String workspaceId;
  NewUser({
    required this.profile,
    required this.workspaceId,
  });
}

abstract class IAuth {
  Future<Either<UserProfile, UserError>> signIn(String? email, String? password);
  Future<Either<UserProfile, UserError>> signUp(String? name, String? password, String? email);
  Future<Either<Unit, UserError>> signOut();
}

abstract class IAuthRouter {
  void pushWelcomeScreen(BuildContext context, UserProfile userProfile);
  void pushSignUpScreen(BuildContext context);
  void pushForgetPasswordScreen(BuildContext context);
  void pushHomeScreen(BuildContext context, UserProfile profile, CurrentWorkspaceSetting workspaceSetting);
}

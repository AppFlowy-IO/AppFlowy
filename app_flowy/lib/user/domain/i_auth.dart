import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

abstract class IAuth {
  Future<Either<UserProfile, UserError>> signIn(
      String? email, String? password);
  Future<Either<UserProfile, UserError>> signUp(
      String? name, String? password, String? email);

  Future<Either<Unit, UserError>> signOut();
}

abstract class IAuthRouter {
  void showWorkspaceSelectScreen(BuildContext context, UserProfile user);
  void showSignUpScreen(BuildContext context);
  void showForgetPasswordScreen(BuildContext context);
}

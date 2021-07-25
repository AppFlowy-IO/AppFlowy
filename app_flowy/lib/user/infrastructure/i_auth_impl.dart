import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:flutter/material.dart';

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

class AuthRouterImpl extends IAuthRouter {
  @override
  void showForgetPasswordScreen(BuildContext context) {
    // TODO: implement showForgetPasswordScreen
  }

  @override
  void showHomeScreen(BuildContext context, UserDetail user) {
    Navigator.of(context).push(PageRoutes.fade(() => HomeScreen(user)));
  }

  @override
  void showSignUpScreen(BuildContext context) {
    // TODO: implement showSignUpScreen
  }
}

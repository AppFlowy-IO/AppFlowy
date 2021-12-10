import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/domain/i_splash.dart';
import 'package:app_flowy/user/presentation/sign_up_screen.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/protobuf/flowy-user-infra/protobuf.dart' show UserProfile;
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/protobuf.dart';
import 'package:flutter/material.dart';

class AuthImpl extends IAuth {
  AuthRepository repo;
  AuthImpl({
    required this.repo,
  });

  @override
  Future<Either<UserProfile, UserError>> signIn(String? email, String? password) {
    return repo.signIn(email: email, password: password);
  }

  @override
  Future<Either<UserProfile, UserError>> signUp(String? name, String? password, String? email) {
    return repo.signUp(name: name, password: password, email: email);
  }

  @override
  Future<Either<Unit, UserError>> signOut() {
    return repo.signOut();
  }
}

class AuthRouterImpl extends IAuthRouter {
  @override
  void pushForgetPasswordScreen(BuildContext context) {
    // TODO: implement showForgetPasswordScreen
  }

  @override
  void pushWelcomeScreen(BuildContext context, UserProfile userProfile) {
    getIt<ISplashRoute>().pushWelcomeScreen(context, userProfile);
  }

  @override
  void pushSignUpScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRoutes.fade(
        () => SignUpScreen(router: getIt<IAuthRouter>()),
      ),
    );
  }

  @override
  void pushHomeScreen(BuildContext context, UserProfile profile, CurrentWorkspaceSetting workspaceSetting) {
    Navigator.push(
      context,
      PageRoutes.fade(() => HomeScreen(profile, workspaceSetting), RouteDurations.slow.inMilliseconds * .001),
    );
  }
}

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/auth_service.dart';
import 'package:app_flowy/user/presentation/sign_in_screen.dart';
import 'package:app_flowy/user/presentation/sign_up_screen.dart';
import 'package:app_flowy/user/presentation/skip_log_in_screen.dart';
import 'package:app_flowy/user/presentation/welcome_screen.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/protobuf.dart';
import 'package:flutter/material.dart';

class AuthRouter {
  void pushForgetPasswordScreen(BuildContext context) {
    // TODO: implement showForgetPasswordScreen
  }

  void pushWelcomeScreen(BuildContext context, UserProfile userProfile) {
    getIt<SplashRoute>().pushWelcomeScreen(context, userProfile);
  }

  void pushSignUpScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRoutes.fade(
        () => SignUpScreen(router: getIt<AuthRouter>()),
      ),
    );
  }

  void pushHomeScreen(BuildContext context, UserProfile profile, CurrentWorkspaceSetting workspaceSetting) {
    Navigator.push(
      context,
      PageRoutes.fade(() => HomeScreen(profile, workspaceSetting), RouteDurations.slow.inMilliseconds * .001),
    );
  }
}

class SplashRoute {
  Future<void> pushWelcomeScreen(BuildContext context, UserProfile userProfile) async {
    final screen = WelcomeScreen(userProfile: userProfile);
    final workspaceId = await Navigator.of(context).push(
      PageRoutes.fade(
        () => screen,
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );

    pushHomeScreen(context, userProfile, workspaceId);
  }

  void pushHomeScreen(BuildContext context, UserProfile userProfile, CurrentWorkspaceSetting workspaceSetting) {
    Navigator.push(
      context,
      PageRoutes.fade(() => HomeScreen(userProfile, workspaceSetting), RouteDurations.slow.inMilliseconds * .001),
    );
  }

  void pushSignInScreen(BuildContext context) {
    Navigator.push(
      context,
      PageRoutes.fade(() => SignInScreen(router: getIt<AuthRouter>()), RouteDurations.slow.inMilliseconds * .001),
    );
  }

  void pushSkipLoginScreen(BuildContext context) {
    Navigator.push(
      context,
      PageRoutes.fade(
          () => SkipLogInScreen(
                router: getIt<AuthRouter>(),
                authService: getIt<AuthService>(),
              ),
          RouteDurations.slow.inMilliseconds * .001),
    );
  }
}

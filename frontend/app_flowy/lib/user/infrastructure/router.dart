import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/domain/i_splash.dart';
import 'package:app_flowy/user/presentation/sign_up_screen.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/protobuf.dart';
import 'package:flutter/material.dart';

class AuthRouter {
  @override
  void pushForgetPasswordScreen(BuildContext context) {
    // TODO: implement showForgetPasswordScreen
  }

  void pushWelcomeScreen(BuildContext context, UserProfile userProfile) {
    getIt<ISplashRoute>().pushWelcomeScreen(context, userProfile);
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

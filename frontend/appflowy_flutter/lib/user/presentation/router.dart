import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy/user/presentation/sign_up_screen.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/user/presentation/welcome_screen.dart';
import 'package:appflowy/workspace/presentation/home/home_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';

class AuthRouter {
  void pushForgetPasswordScreen(BuildContext context) {}

  void pushWelcomeScreen(BuildContext context, UserProfilePB userProfile) {
    getIt<SplashRoute>().pushWelcomeScreen(context, userProfile);
  }

  void pushSignUpScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRoutes.fade(
        () => SignUpScreen(router: getIt<AuthRouter>()),
      ),
    );
  }

  void pushHomeScreenWithWorkSpace(
    BuildContext context,
    UserProfilePB profile,
    WorkspaceSettingPB workspaceSetting,
  ) {
    Navigator.push(
      context,
      PageRoutes.fade(
        () => HomeScreen(
          profile,
          workspaceSetting,
          key: ValueKey(profile.id),
        ),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }

  Future<void> pushHomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    final result = await FolderEventGetCurrentWorkspace().send();
    result.fold(
      (workspaceSettingPB) => pushHomeScreenWithWorkSpace(
        context,
        userProfile,
        workspaceSettingPB,
      ),
      (r) => pushWelcomeScreen(context, userProfile),
    );
  }
}

class SplashRoute {
  Future<void> pushWelcomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    final screen = WelcomeScreen(userProfile: userProfile);
    await Navigator.of(context).push(
      PageRoutes.fade(
        () => screen,
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );

    FolderEventGetCurrentWorkspace().send().then((result) {
      result.fold(
        (workspaceSettingPB) =>
            pushHomeScreen(context, userProfile, workspaceSettingPB),
        (r) => null,
      );
    });
  }

  void pushHomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
    WorkspaceSettingPB workspaceSetting,
  ) {
    Navigator.push(
      context,
      PageRoutes.fade(
        () => HomeScreen(
          userProfile,
          workspaceSetting,
          key: ValueKey(userProfile.id),
        ),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }

  void pushSignInScreen(BuildContext context) {
    Navigator.push(
      context,
      PageRoutes.fade(
        () => SignInScreen(router: getIt<AuthRouter>()),
        RouteDurations.slow.inMilliseconds * .001,
      ),
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
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }
}

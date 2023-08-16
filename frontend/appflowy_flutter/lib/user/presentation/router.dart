import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen.dart';
import 'package:appflowy/workspace/presentation/home/home_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';

class AuthRouter {
  void pushForgetPasswordScreen(BuildContext context) {}

  void pushWorkspaceStartScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) {
    getIt<SplashRouter>().pushWorkspaceStartScreen(context, userProfile);
  }

  void pushSignUpScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRoutes.fade(
        () => SignUpScreen(router: getIt<AuthRouter>()),
        const RouteSettings(name: SignUpScreen.routeName),
      ),
    );
  }

  void pushHomeScreen(
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
        const RouteSettings(name: HomeScreen.routeName),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }

  Future<void> pushHomeOrWorkspaceStartScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    // retrieve user's workspace
    final result = await FolderEventGetCurrentWorkspace().send();
    result.fold(
      // if user has workspace, push [HomeScreen]
      (workspaceSettingPB) => pushHomeScreen(
        context,
        userProfile,
        workspaceSettingPB,
      ),
      // if user has no workspace, push [WorkspaceStartScreen]
      (r) => pushWorkspaceStartScreen(context, userProfile),
    );
  }

  Future<void> pushEncryptionScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    Navigator.push(
      context,
      PageRoutes.fade(
        () => EncryptSecretScreen(
          user: userProfile,
          key: ValueKey(userProfile.id),
        ),
        const RouteSettings(name: EncryptSecretScreen.routeName),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }

  Future<void> pushWorkspaceErrorScreen(
    BuildContext context,
    UserFolderPB userFolder,
    FlowyError error,
  ) async {
    final screen = WorkspaceErrorScreen(
      userFolder: userFolder,
      error: error,
    );
    await Navigator.of(context).push(
      PageRoutes.fade(
        () => screen,
        const RouteSettings(name: WorkspaceErrorScreen.routeName),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }
}

class SplashRouter {
  Future<void> pushWorkspaceStartScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    final screen = WorkspaceStartScreen(userProfile: userProfile);
    await Navigator.of(context).push(
      PageRoutes.fade(
        () => screen,
        const RouteSettings(name: WorkspaceStartScreen.routeName),
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
        const RouteSettings(
          name: WorkspaceStartScreen.routeName,
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
        const RouteSettings(name: SignInScreen.routeName),
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
        const RouteSettings(name: SkipLogInScreen.routeName),
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );
  }
}

import 'package:appflowy/mobile/presentation/mobile_home_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/workspace_start_screen.dart';
import 'package:appflowy/workspace/presentation/home/home_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/util/platform_extension.dart';

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

  /// Navigates to the home screen based on the current workspace and platform.
  ///
  /// This function takes in a [BuildContext] and a [UserProfilePB] object to
  /// determine the user's settings and then navigate to the appropriate home screen
  /// (`MobileHomeScreen` for mobile platforms, `DesktopHomeScreen` for others).
  ///
  /// It first fetches the current workspace settings using [FolderEventGetCurrentWorkspace].
  /// If the workspace settings are successfully fetched, it navigates to the home screen.
  /// If there's an error, it defaults to the workspace start screen.
  ///
  /// @param [context] BuildContext for navigating to the appropriate screen.
  /// @param [userProfile] UserProfilePB object containing the details of the current user.
  ///
  Future<void> pushHomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    final result = await FolderEventGetCurrentWorkspace().send();
    result.fold(
      (workspaceSetting) {
        if (PlatformExtension.isMobile) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => MobileHomeScreen(
                key: ValueKey(userProfile.id),
                userProfile: userProfile,
                workspaceSetting: workspaceSetting,
              ),
            ),
            // pop up all the pages until [SplashScreen]
            (route) => route.settings.name == SplashScreen.routeName,
          );
        } else {
          Navigator.push(
            context,
            PageRoutes.fade(
              () => DesktopHomeScreen(
                key: ValueKey(userProfile.id),
                userProfile: userProfile,
                workspaceSetting: workspaceSetting,
              ),
              const RouteSettings(
                name: DesktopHomeScreen.routeName,
              ),
              RouteDurations.slow.inMilliseconds * .001,
            ),
          );
        }
      },
      (error) => pushWorkspaceStartScreen(context, userProfile),
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
    if (PlatformExtension.isMobile) {
      Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) => MobileHomeScreen(
            key: ValueKey(userProfile.id),
            userProfile: userProfile,
            workspaceSetting: workspaceSetting,
          ),
        ),
        // pop up all the pages until [SplashScreen]
        (route) => route.settings.name == SplashScreen.routeName,
      );
    } else {
      Navigator.push(
        context,
        PageRoutes.fade(
          () => DesktopHomeScreen(
            userProfile: userProfile,
            workspaceSetting: workspaceSetting,
            key: ValueKey(userProfile.id),
          ),
          const RouteSettings(
            name: DesktopHomeScreen.routeName,
          ),
          RouteDurations.slow.inMilliseconds * .001,
        ),
      );
    }
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

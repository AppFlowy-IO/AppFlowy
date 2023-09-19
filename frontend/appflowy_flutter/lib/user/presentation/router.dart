import 'package:appflowy/mobile/presentation/mobile_home_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/user/presentation/screens/workspace_start_screen/workspace_start_screen.dart';
import 'package:appflowy/workspace/presentation/home/desktop_home_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:go_router/go_router.dart';

class AuthRouter {
  void pushForgetPasswordScreen(BuildContext context) {}

  void pushWorkspaceStartScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) {
    getIt<SplashRouter>().pushWorkspaceStartScreen(context, userProfile);
  }

  void pushSignUpScreen(BuildContext context) {
    context.push(SignUpScreen.routeName);
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
  Future<void> goHomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    final result = await FolderEventGetCurrentWorkspace().send();
    result.fold(
      (workspaceSetting) {
        // Replace SignInScreen or SkipLogInScreen as root page.
        // If user click back button, it will exit app rather than go back to SignInScreen or SkipLogInScreen
        if (PlatformExtension.isMobile) {
          context.go(
            MobileHomeScreen.routeName,
          );
        } else {
          context.go(
            DesktopHomeScreen.routeName,
            extra: {
              'key': ValueKey(userProfile.id),
              'userProfile': userProfile,
              'workspaceSetting': workspaceSetting,
            },
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
    // After log in,push EncryptionScreen on the top SignInScreen
    context.push(
      EncryptSecretScreen.routeName,
      extra: {
        'userProfile': userProfile,
        'key': ValueKey(userProfile.id),
      },
    );
  }

  Future<void> pushWorkspaceErrorScreen(
    BuildContext context,
    UserFolderPB userFolder,
    FlowyError error,
  ) async {
    await context.push(
      WorkspaceErrorScreen.routeName,
      extra: {
        'userFolder': userFolder,
        'error': error,
      },
    );
  }
}

class SplashRouter {
  // Unused for now, it was planed to be used in SignUpScreen.
  // To let user choose workspace than navigate to corresponding home screen.
  Future<void> pushWorkspaceStartScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) async {
    await context.push(
      WorkspaceStartScreen.routeName,
      extra: {
        'userProfile': userProfile,
      },
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
      context.push(
        MobileHomeScreen.routeName,
      );
    } else {
      context.push(
        DesktopHomeScreen.routeName,
        extra: {
          'key': ValueKey(userProfile.id),
          'userProfile': userProfile,
          'workspaceSetting': workspaceSetting,
        },
      );
    }
  }

  void goHomeScreen(
    BuildContext context,
    UserProfilePB userProfile,
    WorkspaceSettingPB workspaceSetting,
  ) {
    if (PlatformExtension.isMobile) {
      context.go(
        MobileHomeScreen.routeName,
      );
    } else {
      context.go(
        DesktopHomeScreen.routeName,
        extra: {
          'key': ValueKey(userProfile.id),
          'userProfile': userProfile,
          'workspaceSetting': workspaceSetting,
        },
      );
    }
  }
}

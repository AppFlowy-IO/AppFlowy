import 'package:appflowy/mobile/presentation/home/mobile_home_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/workspace/presentation/home/desktop_home_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
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
    final result = await FolderEventGetCurrentWorkspaceSetting().send();
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
          );
        }
      },
      (error) => pushWorkspaceStartScreen(context, userProfile),
    );
  }

  void pushEncryptionScreen(
    BuildContext context,
    UserProfilePB userProfile,
  ) {
    // After log in,push EncryptionScreen on the top SignInScreen
    context.push(
      EncryptSecretScreen.routeName,
      extra: {
        EncryptSecretScreen.argUser: userProfile,
        EncryptSecretScreen.argKey: ValueKey(userProfile.id),
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
        WorkspaceErrorScreen.argUserFolder: userFolder,
        WorkspaceErrorScreen.argError: error,
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
        WorkspaceStartScreen.argUserProfile: userProfile,
      },
    );

    final result = await FolderEventGetCurrentWorkspaceSetting().send();
    result.fold(
      (workspaceSettingPB) => pushHomeScreen(context),
      (r) => null,
    );
  }

  void pushHomeScreen(
    BuildContext context,
  ) {
    if (PlatformExtension.isMobile) {
      context.push(
        MobileHomeScreen.routeName,
      );
    } else {
      context.push(
        DesktopHomeScreen.routeName,
      );
    }
  }

  void goHomeScreen(
    BuildContext context,
  ) {
    if (PlatformExtension.isMobile) {
      context.go(
        MobileHomeScreen.routeName,
      );
    } else {
      context.go(
        DesktopHomeScreen.routeName,
      );
    }
  }
}

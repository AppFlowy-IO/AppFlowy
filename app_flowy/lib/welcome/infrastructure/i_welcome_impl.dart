import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/sign_in/sign_in_screen.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_welcome.dart';
import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:app_flowy/workspace/presentation/workspace/workspace_select_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart' as workspace;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:app_flowy/welcome/domain/i_welcome.dart';

class WelcomeAuthImpl implements IWelcomeAuth {
  @override
  Future<AuthState> currentUserProfile() {
    final result = UserEventGetUserProfile().send();
    return result.then((result) {
      return result.fold(
        (UserProfile) {
          return AuthState.authenticated(UserProfile);
        },
        (userError) {
          return AuthState.unauthenticated(userError);
        },
      );
    });
  }
}

class WelcomeRoute implements IWelcomeRoute {
  @override
  Future<void> pushHomeScreen(BuildContext context, UserProfile user) async {
    final repo = UserRepo(user: user);
    return WorkspaceEventReadCurWorkspace().send().then(
      (result) {
        return result.fold(
          (workspace) =>
              _pushToScreen(context, HomeScreen(repo.user, workspace.id)),
          (error) async {
            assert(error.code == workspace.ErrorCode.CurrentWorkspaceNotFound);
            final screen = WorkspaceSelectScreen(repo: repo);
            final workspaceId = await Navigator.of(context).push(
              PageRoutes.fade(
                () => screen,
                RouteDurations.slow.inMilliseconds * .001,
              ),
            );

            _pushToScreen(context, HomeScreen(repo.user, workspaceId));
          },
        );
      },
    );
  }

  @override
  Widget pushSignInScreen() {
    return SignInScreen(router: getIt<IAuthRouter>());
  }

  void _pushToScreen(BuildContext context, Widget screen) {
    Navigator.push(
        context,
        PageRoutes.fade(
            () => screen, RouteDurations.slow.inMilliseconds * .001));
  }
}

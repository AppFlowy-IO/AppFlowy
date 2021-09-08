import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/sign_in_screen.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_splash.dart';
import 'package:app_flowy/workspace/infrastructure/repos/user_repo.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:app_flowy/welcome/presentation/welcome_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/route/animation.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:app_flowy/welcome/domain/i_splash.dart';

class SplashUserImpl implements ISplashUser {
  @override
  Future<AuthState> currentUserProfile() {
    final result = UserEventGetUserProfile().send();
    return result.then((result) {
      return result.fold(
        (userProfile) {
          return AuthState.authenticated(userProfile);
        },
        (userError) {
          return AuthState.unauthenticated(userError);
        },
      );
    });
  }
}


class SplashRoute implements ISplashRoute {
  @override
  Future<void> pushWelcomeScreen(BuildContext context, UserProfile user) async {
    final repo = UserRepo(user: user);
    final screen = WelcomeScreen(repo: repo);
    final workspaceId = await Navigator.of(context).push(
      PageRoutes.fade(
        () => screen,
        RouteDurations.slow.inMilliseconds * .001,
      ),
    );

    pushHomeScreen(context, repo.user, workspaceId);
  }

  @override
  void pushHomeScreen(
      BuildContext context, UserProfile userProfile, String workspaceId) {
    Navigator.push(
      context,
      PageRoutes.fade(() => HomeScreen(userProfile, workspaceId),
          RouteDurations.slow.inMilliseconds * .001),
    );
  }

  @override
  void pushSignInScreen(BuildContext context) {
    Navigator.push(
      context,
      PageRoutes.fade(() => SignInScreen(router: getIt<IAuthRouter>()),
          RouteDurations.slow.inMilliseconds * .001),
    );
  }
}

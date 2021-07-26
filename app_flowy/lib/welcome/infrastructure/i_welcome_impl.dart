import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/sign_in/sign_in_screen.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/i_welcome.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:app_flowy/welcome/domain/i_welcome.dart';

class WelcomeAuthImpl implements IWelcomeAuth {
  @override
  Future<AuthState> currentUserDetail() {
    final result = UserEventGetStatus().send();
    return result.then((result) {
      return result.fold(
        (userDetail) {
          return AuthState.authenticated(userDetail);
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
  Widget pushHomeScreen(UserDetail user) {
    return HomeScreen(user);
  }

  @override
  Widget pushSignInScreen() {
    return SignInScreen(router: getIt<IAuthRouter>());
  }
}

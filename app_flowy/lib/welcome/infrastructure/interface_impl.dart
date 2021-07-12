import 'package:app_flowy/home/application/edit_pannel/edit_pannel_bloc.dart';
import 'package:app_flowy/home/application/home_bloc.dart';
import 'package:app_flowy/home/application/menu/menu_bloc.dart';
import 'package:app_flowy/home/application/watcher/home_watcher_bloc.dart';
import 'package:app_flowy/home/presentation/home_screen.dart';
import 'package:app_flowy/welcome/application/welcome_bloc.dart';
import 'package:app_flowy/welcome/domain/auth_state.dart';
import 'package:app_flowy/welcome/domain/interface.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class Welcome {
  static Future<void> dependencyResolved(GetIt getIt) async {
    getIt.registerFactory<IWelcomeAuth>(() => WelcomeAuthImpl());
    getIt.registerFactory<IWelcomeRoute>(() => WelcomeRoute());
    getIt.registerFactory<HomeBloc>(() => HomeBloc());
    getIt.registerFactory<HomeWatcherBloc>(() => HomeWatcherBloc());
    getIt.registerFactory<EditPannelBloc>(() => EditPannelBloc());

    getIt.registerFactory<MenuBloc>(() => MenuBloc());

    getIt
        .registerFactory<WelcomeBloc>(() => WelcomeBloc(getIt<IWelcomeAuth>()));
  }
}

class WelcomeAuthImpl implements IWelcomeAuth {
  @override
  Future<AuthState> currentUserState() {
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
    return Container(
      width: 100,
      height: 100,
      color: Colors.red,
    );
  }
}

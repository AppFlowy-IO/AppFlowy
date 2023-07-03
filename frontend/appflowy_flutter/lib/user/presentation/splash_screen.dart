import 'package:appflowy/startup/tasks/supabase_task.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../startup/startup.dart';
import '../application/splash_bloc.dart';
import '../domain/auth_state.dart';
import 'router.dart';

// [[diagram: splash screen]]
// ┌────────────────┐1.get user ┌──────────┐     ┌────────────┐ 2.send UserEventCheckUser
// │  SplashScreen  │──────────▶│SplashBloc│────▶│ISplashUser │─────┐
// └────────────────┘           └──────────┘     └────────────┘     │
//                                                                  │
//                                                                  ▼
//    ┌───────────┐            ┌─────────────┐                 ┌────────┐
//    │HomeScreen │◀───────────│BlocListener │◀────────────────│RustSDK │
//    └───────────┘            └─────────────┘                 └────────┘
//           4. Show HomeScreen or SignIn      3.return AuthState
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    Key? key,
    required this.autoRegister,
  }) : super(key: key);

  final bool autoRegister;

  @override
  Widget build(BuildContext context) {
    if (!autoRegister) {
      return _buildChild(context);
    } else {
      return FutureBuilder<void>(
        future: _registerIfNeeded(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Container();
          }
          return _buildChild(context);
        },
      );
    }
  }

  BlocProvider<SplashBloc> _buildChild(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return getIt<SplashBloc>()..add(const SplashEvent.getUser());
      },
      child: Scaffold(
        body: BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            state.auth.map(
              authenticated: (r) => _handleAuthenticated(context, r),
              unauthenticated: (r) => _handleUnauthenticated(context, r),
              initial: (r) => {},
            );
          },
          child: const Body(),
        ),
      ),
    );
  }

  Future<void> _handleAuthenticated(
    BuildContext context,
    Authenticated authenticated,
  ) async {
    final userProfile = authenticated.userProfile;
    final result = await FolderEventGetCurrentWorkspace().send();
    result.fold(
      (workspaceSetting) {
        getIt<SplashRoute>().pushHomeScreen(
          context,
          userProfile,
          workspaceSetting,
        );
      },
      (error) async {
        Log.error(error);
        getIt<SplashRoute>().pushWelcomeScreen(context, userProfile);
      },
    );
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    // if the env is not configured, we will skip to the 'skip login screen'.
    if (isSupabaseEnable) {
      getIt<SplashRoute>().pushSignInScreen(context);
    } else {
      getIt<SplashRoute>().pushSkipLoginScreen(context);
    }
  }

  Future<void> _registerIfNeeded() async {
    final result = await UserEventCheckUser().send();
    if (!result.isLeft()) {
      await getIt<AuthService>().signUpAsGuest();
    }
  }
}

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
              image:
                  const AssetImage('assets/images/appflowy_launch_splash.jpg'),
            ),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}

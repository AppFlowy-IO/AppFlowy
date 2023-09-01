import 'package:appflowy/env/env.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../startup/startup.dart';
import '../application/splash_bloc.dart';
import '../domain/auth_state.dart';
import 'router.dart';

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

  /// Handles the authentication flow once a user is authenticated.
  Future<void> _handleAuthenticated(
    BuildContext context,
    Authenticated authenticated,
  ) async {
    final userProfile = authenticated.userProfile;

    /// After a user is authenticated, this function checks if encryption is required.
    final result = await UserEventCheckEncryptionSign().send();
    result.fold(
      (check) async {
        /// If encryption is needed, the user is navigated to the encryption screen.
        /// Otherwise, it fetches the current workspace for the user and navigates them
        if (check.isNeedSecret) {
          getIt<AuthRouter>().pushEncryptionScreen(context, userProfile);
        } else {
          final result = await FolderEventGetCurrentWorkspace().send();
          result.fold(
            (workspaceSetting) {
              getIt<SplashRoute>().pushHomeScreen(
                context,
                userProfile,
                workspaceSetting,
              );
            },
            (error) {
              handleOpenWorkspaceError(context, error);
            },
          );
        }
      },
      (err) {
        Log.error(err);
      },
    );
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    // if the env is not configured, we will skip to the 'skip login screen'.
    if (isSupabaseEnabled) {
      getIt<SplashRoute>().pushSignInScreen(context);
    } else {
      getIt<SplashRoute>().pushSkipLoginScreen(context);
    }
  }

  Future<void> _registerIfNeeded() async {
    final result = await UserEventGetUserProfile().send();
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

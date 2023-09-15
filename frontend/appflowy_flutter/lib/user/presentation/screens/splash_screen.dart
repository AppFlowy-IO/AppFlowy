import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/splash_bloc.dart';
import 'package:appflowy/user/domain/auth_state.dart';
import 'package:appflowy/user/presentation/helpers/helpers.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    super.key,
    required this.autoRegister,
  });

  static const routeName = '/SplashScreen';
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
              getIt<SplashRouter>().pushHomeScreen(
                context,
                userProfile,
                workspaceSetting,
              );
            },
            (error) => handleOpenWorkspaceError(context, error),
          );
        }
      },
      (err) {
        Log.error(err);
      },
    );
  }

  void _handleUnauthenticated(BuildContext context, Unauthenticated result) {
    Log.debug(
      '_handleUnauthenticated -> Supabase is enabled: $isSupabaseEnabled',
    );
    // if the env is not configured, we will skip to the 'skip login screen'.
    if (isSupabaseEnabled) {
      getIt<SplashRouter>().pushSignInScreen(context);
    } else {
      getIt<SplashRouter>().pushSkipLoginScreen(context);
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
  const Body({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: PlatformExtension.isMobile
          ? const FlowySvg(
              FlowySvgs.flowy_logo_xl,
              blendMode: null,
            )
          : const _DesktopSplashBody(),
    );
  }
}

class _DesktopSplashBody extends StatelessWidget {
  const _DesktopSplashBody();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            image: const AssetImage(
              'assets/images/appflowy_launch_splash.jpg',
            ),
          ),
          const CircularProgressIndicator.adaptive(),
        ],
      ),
    );
  }
}

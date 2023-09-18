import 'package:appflowy/mobile/presentation/mobile_home_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter generateRouter(Widget child) {
  return GoRouter(
    navigatorKey: AppGlobals.rootNavKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        // Root route is SplashScreen.
        // It needs LaunchConfiguration as a parameter, so we get it from ApplicationWidget's child.
        pageBuilder: (context, state) => MaterialPage(
          child: child,
        ),
      ),
      // Routes in both desktop and mobile
      GoRoute(
        path: SignInScreen.routeName,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: SignInScreen(router: getIt<AuthRouter>()),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      GoRoute(
        path: SkipLogInScreen.routeName,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: SkipLogInScreen(
              authRouter: getIt<AuthRouter>(),
              authService: getIt<AuthService>(),
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      GoRoute(
        path: EncryptSecretScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: EncryptSecretScreen(
              user: args['user'],
              key: args['key'],
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      GoRoute(
        path: WorkspaceErrorScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: EncryptSecretScreen(
              user: args['userFolder'],
              key: args['error'],
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      // Desktop only
      GoRoute(
        path: DesktopHomeScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: DesktopHomeScreen(
              key: args['key'],
              userProfile: args['userProfile'],
              workspaceSetting: args['workspaceSetting'],
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      // Mobile only
      GoRoute(
        path: MobileHomeScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return MaterialPage(
            child: MobileHomeScreen(
              key: args['key'],
              userProfile: args['userProfile'],
              workspaceSetting: args['workspaceSetting'],
            ),
          );
        },
      ),

      // Unused for now, it may need to be used in the future.
      // Desktop and Mobile
      GoRoute(
        path: WorkspaceStartScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: WorkspaceStartScreen(
              userProfile: args['userProfile'],
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
      GoRoute(
        path: SignUpScreen.routeName,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: SignUpScreen(
              router: getIt<AuthRouter>(),
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: Duration(
              milliseconds: (RouteDurations.slow.inMilliseconds).round(),
            ),
          );
        },
      ),
    ],
  );
}

Widget _buildFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    FadeTransition(opacity: animation, child: child);

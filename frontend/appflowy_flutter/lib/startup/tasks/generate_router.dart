import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy/workspace/presentation/home/desktop_home_screen.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter generateRouter(Widget child) {
  return GoRouter(
    navigatorKey: AppGlobals.rootNavKey,
    initialLocation: '/',
    routes: [
      // Root route is SplashScreen.
      // It needs LaunchConfiguration as a parameter, so we get it from ApplicationWidget's child.
      _rootRoute(child),
      // Routes in both desktop and mobile
      _signInScreenRoute(),
      _skipLogInScreenRoute(),
      _encryptSecretScreenRoute(),
      _workspaceErrorScreenRoute(),
      // Desktop only
      if (!PlatformExtension.isMobile) _desktopHomeScreenRoute(),
      // Mobile only
      if (PlatformExtension.isMobile) _mobileHomeScreenWithNavigationBarRoute(),

      // Unused routes for now, it may need to be used in the future.
      // TODO(yijing): extract route method like other routes when it comes to be used.
      // Desktop and Mobile
      GoRoute(
        path: WorkspaceStartScreen.routeName,
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            child: WorkspaceStartScreen(
              userProfile: args[WorkspaceStartScreen.argUserProfile],
            ),
            transitionsBuilder: _buildFadeTransition,
            transitionDuration: _slowDuration,
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
            transitionDuration: _slowDuration,
          );
        },
      ),
    ],
  );
}

/// We use StatefulShellRoute to create a StatefulNavigationShell(ScaffoldWithNavBar) to access to multiple pages, and each page retains its own state.
StatefulShellRoute _mobileHomeScreenWithNavigationBarRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell navigationShell,
    ) {
      // Return the widget that implements the custom shell (in this case
      // using a BottomNavigationBar). The StatefulNavigationShell is passed
      // to be able access the state of the shell and to navigate to other
      // branches in a stateful way.
      return MobileBottomNavigationBar(navigationShell: navigationShell);
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            // The screen to display as the root in the first tab of the
            // bottom navigation bar.
            path: MobileHomeScreen.routeName,
            builder: (BuildContext context, GoRouterState state) {
              return const MobileHomeScreen();
            },
          ),
        ],
      ),
      // TODO(yijing): implement other tabs later
      // The following code comes from the example of StatefulShellRoute.indexedStack. I left there just for placeholder purpose. They will be updated in the future.
      // The route branch for the second tab of the bottom navigation bar.
      StatefulShellBranch(
        // It's not necessary to provide a navigatorKey if it isn't also
        // needed elsewhere. If not provided, a default key will be used.
        routes: <RouteBase>[
          GoRoute(
            // The screen to display as the root in the second tab of the
            // bottom navigation bar.
            path: '/b',
            builder: (BuildContext context, GoRouterState state) =>
                const RootPlaceholderScreen(
              label: 'Favorite',
              detailsPath: '/b/details/1',
              secondDetailsPath: '/b/details/2',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'details/:param',
                builder: (BuildContext context, GoRouterState state) =>
                    DetailsPlaceholderScreen(
                  label: 'Favorite details',
                  param: state.pathParameters['param'],
                ),
              ),
            ],
          ),
        ],
      ),

      // The route branch for the third tab of the bottom navigation bar.
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            // The screen to display as the root in the third tab of the
            // bottom navigation bar.
            path: '/c',
            builder: (BuildContext context, GoRouterState state) =>
                const RootPlaceholderScreen(
              label: 'Add Document',
              detailsPath: '/c/details',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'details',
                builder: (BuildContext context, GoRouterState state) =>
                    DetailsPlaceholderScreen(
                  label: 'Add Document details',
                  extra: state.extra,
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '/d',
            builder: (BuildContext context, GoRouterState state) =>
                const RootPlaceholderScreen(
              label: 'Search',
              detailsPath: '/d/details',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'details',
                builder: (BuildContext context, GoRouterState state) =>
                    const DetailsPlaceholderScreen(
                  label: 'Search Page details',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: '/e',
            builder: (BuildContext context, GoRouterState state) =>
                const RootPlaceholderScreen(
              label: 'Notification',
              detailsPath: '/e/details',
            ),
            routes: <RouteBase>[
              GoRoute(
                path: 'details',
                builder: (BuildContext context, GoRouterState state) =>
                    const DetailsPlaceholderScreen(
                  label: 'Notification Page details',
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

GoRoute _desktopHomeScreenRoute() {
  return GoRoute(
    path: DesktopHomeScreen.routeName,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        child: const DesktopHomeScreen(),
        transitionsBuilder: _buildFadeTransition,
        transitionDuration: _slowDuration,
      );
    },
  );
}

GoRoute _workspaceErrorScreenRoute() {
  return GoRoute(
    path: WorkspaceErrorScreen.routeName,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return CustomTransitionPage(
        child: WorkspaceErrorScreen(
          error: args[WorkspaceErrorScreen.argError],
          userFolder: args[WorkspaceErrorScreen.argUserFolder],
        ),
        transitionsBuilder: _buildFadeTransition,
        transitionDuration: _slowDuration,
      );
    },
  );
}

GoRoute _encryptSecretScreenRoute() {
  return GoRoute(
    path: EncryptSecretScreen.routeName,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return CustomTransitionPage(
        child: EncryptSecretScreen(
          user: args[EncryptSecretScreen.argUser],
          key: args[EncryptSecretScreen.argKey],
        ),
        transitionsBuilder: _buildFadeTransition,
        transitionDuration: _slowDuration,
      );
    },
  );
}

GoRoute _skipLogInScreenRoute() {
  return GoRoute(
    path: SkipLogInScreen.routeName,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        child: const SkipLogInScreen(),
        transitionsBuilder: _buildFadeTransition,
        transitionDuration: _slowDuration,
      );
    },
  );
}

GoRoute _signInScreenRoute() {
  return GoRoute(
    path: SignInScreen.routeName,
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        child: const SignInScreen(),
        transitionsBuilder: _buildFadeTransition,
        transitionDuration: _slowDuration,
      );
    },
  );
}

GoRoute _rootRoute(Widget child) {
  return GoRoute(
    path: '/',
    redirect: (context, state) async {
      // Every time before navigating to splash screen, we check if user is already logged in in desktop. It is used to skip showing splash screen when user just changes apperance settings like theme mode.
      final userResponse = await getIt<AuthService>().getUser();
      final routeName = userResponse.fold(
        (error) => null,
        (user) => DesktopHomeScreen.routeName,
      );
      if (routeName != null && !PlatformExtension.isMobile) return routeName;

      return null;
    },
    // Root route is SplashScreen.
    // It needs LaunchConfiguration as a parameter, so we get it from ApplicationWidget's child.
    pageBuilder: (context, state) => MaterialPage(
      child: child,
    ),
  );
}

Widget _buildFadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    FadeTransition(opacity: animation, child: child);

Duration _slowDuration = Duration(
  milliseconds: (RouteDurations.slow.inMilliseconds).round(),
);

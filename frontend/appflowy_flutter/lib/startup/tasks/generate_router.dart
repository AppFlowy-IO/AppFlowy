import 'package:appflowy/mobile/presentation/database/mobile_board_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_grid_screen.dart';
import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_page.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
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
      if (PlatformExtension.isMobile) ...[
        // settings
        _mobileHomeSettingPageRoute(),
        _mobileSettingPrivacyPolicyPageRoute(),
        _mobileSettingUserAgreementPageRoute(),

        // view page
        _mobileEditorScreenRoute(),
        _mobileGridScreenRoute(),
        _mobileBoardScreenRoute(),
        _mobileCalendarScreenRoute(),

        // home
        // MobileHomeSettingPage is outside the bottom navigation bar, thus it is not in the StatefulShellRoute.
        _mobileHomeScreenWithNavigationBarRoute(),

        // trash
        _mobileHomeTrashPageRoute(),

        // emoji picker
        _mobileEmojiPickerPageRoute(),
      ],

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
            path: MobileHomeScreen.routeName,
            builder: (BuildContext context, GoRouterState state) {
              return const MobileHomeScreen();
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: MobileFavoriteScreen.routeName,
            builder: (BuildContext context, GoRouterState state) {
              return const MobileFavoriteScreen();
            },
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

GoRoute _mobileHomeSettingPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileHomeSettingPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(child: MobileHomeSettingPage());
    },
  );
}

GoRoute _mobileSettingPrivacyPolicyPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: PrivacyPolicyPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(child: PrivacyPolicyPage());
    },
  );
}

GoRoute _mobileSettingUserAgreementPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: UserAgreementPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(child: UserAgreementPage());
    },
  );
}

GoRoute _mobileHomeTrashPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileHomeTrashPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(child: MobileHomeTrashPage());
    },
  );
}

GoRoute _mobileEmojiPickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileEmojiPickerScreen.routeName,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileEmojiPickerScreen.viewId]!;
      return MaterialPage(
        child: MobileEmojiPickerScreen(
          id: id,
        ),
      );
    },
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

GoRoute _mobileEditorScreenRoute() {
  return GoRoute(
    path: MobileEditorScreen.routeName,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileEditorScreen.viewId]!;
      final title = state.uri.queryParameters[MobileEditorScreen.viewTitle];
      return MaterialPage(
        child: MobileEditorScreen(
          id: id,
          title: title,
        ),
      );
    },
  );
}

GoRoute _mobileGridScreenRoute() {
  return GoRoute(
    path: MobileGridScreen.routeName,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileGridScreen.viewId]!;
      final title = state.uri.queryParameters[MobileGridScreen.viewTitle];
      return MaterialPage(
        child: MobileGridScreen(
          id: id,
          title: title,
        ),
      );
    },
  );
}

GoRoute _mobileBoardScreenRoute() {
  return GoRoute(
    path: MobileBoardScreen.routeName,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileBoardScreen.viewId]!;
      final title = state.uri.queryParameters[MobileBoardScreen.viewTitle];
      return MaterialPage(
        child: MobileBoardScreen(
          id: id,
          title: title,
        ),
      );
    },
  );
}

GoRoute _mobileCalendarScreenRoute() {
  return GoRoute(
    path: MobileCalendarScreen.routeName,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileCalendarScreen.viewId]!;
      final title = state.uri.queryParameters[MobileCalendarScreen.viewTitle]!;
      return MaterialPage(
        child: MobileCalendarScreen(
          id: id,
          title: title,
        ),
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

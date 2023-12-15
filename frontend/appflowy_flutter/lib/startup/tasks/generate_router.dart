import 'package:appflowy/mobile/presentation/database/board/mobile_board_screen.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_create_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_edit_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/date_picker/mobile_date_picker_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_events_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_grid_screen.dart';
import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_page.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_page.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/appflowy_cloud_page.dart';
import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/mobile/presentation/setting/language/language_picker_screen.dart';
import 'package:appflowy/plugins/base/color/color_picker_screen.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_language_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_picker_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_block_settings_screen.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/workspace/presentation/home/desktop_home_screen.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
        _mobileCloudSettingAppFlowyCloudPageRoute(),

        // view page
        _mobileEditorScreenRoute(),
        _mobileGridScreenRoute(),
        _mobileBoardScreenRoute(),
        _mobileCalendarScreenRoute(),
        // card detail page
        _mobileCardDetailScreenRoute(),
        _mobileDateCellEditScreenRoute(),
        _mobileNewPropertyPageRoute(),
        _mobileEditPropertyPageRoute(),

        // home
        // MobileHomeSettingPage is outside the bottom navigation bar, thus it is not in the StatefulShellRoute.
        _mobileHomeScreenWithNavigationBarRoute(),

        // trash
        _mobileHomeTrashPageRoute(),

        // emoji picker
        _mobileEmojiPickerPageRoute(),
        _mobileImagePickerPageRoute(),

        // color picker
        _mobileColorPickerPageRoute(),

        // code language picker
        _mobileCodeLanguagePickerPageRoute(),
        _mobileLanguagePickerPageRoute(),
        _mobileFontPickerPageRoute(),

        // calendar related
        _mobileCalendarEventsPageRoute(),

        _mobileBlockSettingsPageRoute(),
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
            path: MobileNotificationsScreen.routeName,
            builder: (_, __) => const MobileNotificationsScreen(),
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

GoRoute _mobileCloudSettingAppFlowyCloudPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: AppFlowyCloudPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(child: AppFlowyCloudPage());
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

GoRoute _mobileBlockSettingsPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileBlockSettingsScreen.routeName,
    pageBuilder: (context, state) {
      final actionsString =
          state.uri.queryParameters[MobileBlockSettingsScreen.supportedActions];
      final actions = actionsString
          ?.split(',')
          .map(MobileBlockActionType.fromActionString)
          .toList();
      return MaterialPage(
        child: MobileBlockSettingsScreen(
          actions: actions ?? MobileBlockActionType.standard,
        ),
      );
    },
  );
}

GoRoute _mobileEmojiPickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileEmojiPickerScreen.routeName,
    pageBuilder: (context, state) {
      final title =
          state.uri.queryParameters[MobileEmojiPickerScreen.pageTitle];
      return MaterialPage(
        child: MobileEmojiPickerScreen(
          title: title,
        ),
      );
    },
  );
}

GoRoute _mobileColorPickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileColorPickerScreen.routeName,
    pageBuilder: (context, state) {
      final title =
          state.uri.queryParameters[MobileColorPickerScreen.pageTitle] ?? '';
      return MaterialPage(
        child: MobileColorPickerScreen(
          title: title,
        ),
      );
    },
  );
}

GoRoute _mobileImagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileImagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(
        child: MobileImagePickerScreen(),
      );
    },
  );
}

GoRoute _mobileCodeLanguagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileCodeLanguagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(
        child: MobileCodeLanguagePickerScreen(),
      );
    },
  );
}

GoRoute _mobileLanguagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: LanguagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(
        child: LanguagePickerScreen(),
      );
    },
  );
}

GoRoute _mobileFontPickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: FontPickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialPage(
        child: FontPickerScreen(),
      );
    },
  );
}

GoRoute _mobileNewPropertyPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileNewPropertyScreen.routeName,
    pageBuilder: (context, state) {
      final viewId = state
          .uri.queryParameters[MobileNewPropertyScreen.argViewId] as String;
      final fieldTypeId =
          state.uri.queryParameters[MobileNewPropertyScreen.argFieldTypeId] ??
              FieldType.RichText.value.toString();
      final value = int.parse(fieldTypeId);
      return MaterialPage(
        fullscreenDialog: true,
        child: MobileNewPropertyScreen(
          viewId: viewId,
          fieldType: FieldType.valueOf(value),
        ),
      );
    },
  );
}

GoRoute _mobileEditPropertyPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileEditPropertyScreen.routeName,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return MaterialPage(
        fullscreenDialog: true,
        child: MobileEditPropertyScreen(
          viewId: args[MobileEditPropertyScreen.argViewId],
          field: args[MobileEditPropertyScreen.argField],
        ),
      );
    },
  );
}

GoRoute _mobileCalendarEventsPageRoute() {
  return GoRoute(
    path: MobileCalendarEventsScreen.routeName,
    parentNavigatorKey: AppGlobals.rootNavKey,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;

      return MaterialPage(
        child: MobileCalendarEventsScreen(
          calendarBloc: args[MobileCalendarEventsScreen.calendarBlocKey],
          date: args[MobileCalendarEventsScreen.calendarDateKey],
          events: args[MobileCalendarEventsScreen.calendarEventsKey],
          rowCache: args[MobileCalendarEventsScreen.calendarRowCacheKey],
          viewId: args[MobileCalendarEventsScreen.calendarViewIdKey],
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
    parentNavigatorKey: AppGlobals.rootNavKey,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileEditorScreen.viewId]!;
      final title = state.uri.queryParameters[MobileEditorScreen.viewTitle];

      return MaterialPage(child: MobileEditorScreen(id: id, title: title));
    },
  );
}

GoRoute _mobileGridScreenRoute() {
  return GoRoute(
    path: MobileGridScreen.routeName,
    parentNavigatorKey: AppGlobals.rootNavKey,
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
    parentNavigatorKey: AppGlobals.rootNavKey,
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
    parentNavigatorKey: AppGlobals.rootNavKey,
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

GoRoute _mobileCardDetailScreenRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileRowDetailPage.routeName,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      final databaseController =
          args[MobileRowDetailPage.argDatabaseController];
      final rowId = args[MobileRowDetailPage.argRowId]!;

      return MaterialPage(
        child: MobileRowDetailPage(
          databaseController: databaseController,
          rowId: rowId,
        ),
      );
    },
  );
}

GoRoute _mobileDateCellEditScreenRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileDateCellEditScreen.routeName,
    pageBuilder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      final controller = args[MobileDateCellEditScreen.dateCellController];
      final fullScreen = args[MobileDateCellEditScreen.fullScreen];
      return CustomTransitionPage(
        transitionsBuilder: (_, __, ___, child) => child,
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
        child: MobileDateCellEditScreen(
          controller: controller,
          showAsFullScreen: fullScreen ?? true,
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

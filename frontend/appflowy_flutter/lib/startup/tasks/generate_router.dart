import 'dart:convert';

import 'package:appflowy/mobile/presentation/chat/mobile_chat_screen.dart';
import 'package:appflowy/mobile/presentation/database/board/mobile_board_screen.dart';
import 'package:appflowy/mobile/presentation/database/card/card.dart';
import 'package:appflowy/mobile/presentation/database/date_picker/mobile_date_picker_screen.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_create_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_edit_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_events_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_screen.dart';
import 'package:appflowy/mobile/presentation/database/mobile_grid_screen.dart';
import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_page.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_multiple_select_page.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_screen.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_page.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/appflowy_cloud_page.dart';
import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/mobile/presentation/setting/language/language_picker_screen.dart';
import 'package:appflowy/mobile/presentation/setting/launch_settings_page.dart';
import 'package:appflowy/mobile/presentation/setting/workspace/add_members_screen.dart';
import 'package:appflowy/mobile/presentation/setting/workspace/invite_members_screen.dart';
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
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/mobile_feature_flag_screen.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet/route.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../shared/icon_emoji_picker/tab.dart';
import 'af_navigator_observer.dart';

GoRouter generateRouter(Widget child) {
  return GoRouter(
    navigatorKey: AppGlobals.rootNavKey,
    observers: [getIt.get<AFNavigatorObserver>()],
    initialLocation: '/',
    routes: [
      // Root route is SplashScreen.
      // It needs LaunchConfiguration as a parameter, so we get it from ApplicationWidget's child.
      _rootRoute(child),
      // Routes in both desktop and mobile
      _signInScreenRoute(),
      _skipLogInScreenRoute(),
      _workspaceErrorScreenRoute(),
      // Desktop only
      if (UniversalPlatform.isDesktop) _desktopHomeScreenRoute(),
      // Mobile only
      if (UniversalPlatform.isMobile) ...[
        // settings
        _mobileHomeSettingPageRoute(),
        _mobileCloudSettingAppFlowyCloudPageRoute(),
        _mobileLaunchSettingsPageRoute(),
        _mobileFeatureFlagPageRoute(),

        // view page
        _mobileEditorScreenRoute(),
        _mobileGridScreenRoute(),
        _mobileBoardScreenRoute(),
        _mobileCalendarScreenRoute(),
        _mobileChatScreenRoute(),
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

        // notifications
        _mobileNotificationMultiSelectPageRoute(),

        // invite members
        _mobileInviteMembersPageRoute(),
        _mobileAddMembersPageRoute(),
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
    pageBuilder: (context, state, navigationShell) {
      String name = MobileHomeScreen.routeName;
      switch (navigationShell.currentIndex) {
        case 0:
          name = MobileHomeScreen.routeName;
          break;
        case 1:
          name = MobileSearchScreen.routeName;
          break;
        case 2:
          name = MobileFavoriteScreen.routeName;
          break;
        case 3:
          name = MobileNotificationsScreenV2.routeName;
          break;
      }
      return MaterialExtendedPage(
        child: MobileBottomNavigationBar(navigationShell: navigationShell),
        name: name,
      );
    },
    branches: <StatefulShellBranch>[
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            path: MobileHomeScreen.routeName,
            pageBuilder: (context, state) => MaterialExtendedPage(
              child: const MobileHomeScreen(),
              name: MobileHomeScreen.routeName,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            name: MobileSearchScreen.routeName,
            path: MobileSearchScreen.routeName,
            pageBuilder: (context, state) => MaterialExtendedPage(
              child: const MobileSearchScreen(),
              name: MobileSearchScreen.routeName,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            name: MobileFavoriteScreen.routeName,
            path: MobileFavoriteScreen.routeName,
            pageBuilder: (context, state) => MaterialExtendedPage(
              child: const MobileFavoriteScreen(),
              name: MobileFavoriteScreen.routeName,
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: <RouteBase>[
          GoRoute(
            name: MobileNotificationsScreenV2.routeName,
            path: MobileNotificationsScreenV2.routeName,
            pageBuilder: (context, state) => MaterialExtendedPage(
              child: const MobileNotificationsScreenV2(),
              name: MobileNotificationsScreenV2.routeName,
            ),
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
      return const MaterialExtendedPage(
        child: MobileHomeSettingPage(),
        name: MobileHomeSettingPage.routeName,
      );
    },
  );
}

GoRoute _mobileNotificationMultiSelectPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileNotificationsMultiSelectScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: MobileNotificationsMultiSelectScreen(),
        name: MobileNotificationsMultiSelectScreen.routeName,
      );
    },
  );
}

GoRoute _mobileInviteMembersPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: InviteMembersScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: InviteMembersScreen(),
        name: InviteMembersScreen.routeName,
      );
    },
  );
}

GoRoute _mobileAddMembersPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: AddMembersScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: AddMembersScreen(),
        name: AddMembersScreen.routeName,
      );
    },
  );
}

GoRoute _mobileCloudSettingAppFlowyCloudPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: AppFlowyCloudPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: AppFlowyCloudPage(),
        name: AppFlowyCloudPage.routeName,
      );
    },
  );
}

GoRoute _mobileLaunchSettingsPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileLaunchSettingsPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: MobileLaunchSettingsPage(),
        name: MobileLaunchSettingsPage.routeName,
      );
    },
  );
}

GoRoute _mobileFeatureFlagPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: FeatureFlagScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: FeatureFlagScreen(),
        name: FeatureFlagScreen.routeName,
      );
    },
  );
}

GoRoute _mobileHomeTrashPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileHomeTrashPage.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: MobileHomeTrashPage(),
        name: MobileHomeTrashPage.routeName,
      );
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
      return MaterialExtendedPage(
        child: MobileBlockSettingsScreen(
          actions: actions ?? MobileBlockActionType.standard,
        ),
        name: MobileBlockSettingsScreen.routeName,
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
      final selectTabs =
          state.uri.queryParameters[MobileEmojiPickerScreen.selectTabs] ?? '';
      final selectedType = state
          .uri.queryParameters[MobileEmojiPickerScreen.iconSelectedType]
          ?.toPickerTabType();
      final documentId =
          state.uri.queryParameters[MobileEmojiPickerScreen.uploadDocumentId];
      List<PickerTabType> tabs = [];
      try {
        tabs = selectTabs
            .split('-')
            .map((e) => PickerTabType.values.byName(e))
            .toList();
      } on ArgumentError catch (e) {
        Log.error('convert selectTabs to pickerTab error', e);
      }
      return MaterialExtendedPage(
        child: tabs.isEmpty
            ? MobileEmojiPickerScreen(
                title: title,
                selectedType: selectedType,
                documentId: documentId,
              )
            : MobileEmojiPickerScreen(
                title: title,
                selectedType: selectedType,
                tabs: tabs,
                documentId: documentId,
              ),
        name: MobileEmojiPickerScreen.routeName,
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
      return MaterialExtendedPage(
        child: MobileColorPickerScreen(title: title),
        name: MobileColorPickerScreen.routeName,
      );
    },
  );
}

GoRoute _mobileImagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileImagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: MobileImagePickerScreen(),
        name: MobileImagePickerScreen.routeName,
      );
    },
  );
}

GoRoute _mobileCodeLanguagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: MobileCodeLanguagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: MobileCodeLanguagePickerScreen(),
        name: MobileCodeLanguagePickerScreen.routeName,
      );
    },
  );
}

GoRoute _mobileLanguagePickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: LanguagePickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: LanguagePickerScreen(),
        name: LanguagePickerScreen.routeName,
      );
    },
  );
}

GoRoute _mobileFontPickerPageRoute() {
  return GoRoute(
    parentNavigatorKey: AppGlobals.rootNavKey,
    path: FontPickerScreen.routeName,
    pageBuilder: (context, state) {
      return const MaterialExtendedPage(
        child: FontPickerScreen(),
        name: FontPickerScreen.routeName,
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
      return MaterialExtendedPage(
        fullscreenDialog: true,
        child: MobileNewPropertyScreen(
          viewId: viewId,
          fieldType: FieldType.valueOf(value),
        ),
        name: MobileNewPropertyScreen.routeName,
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
      return MaterialExtendedPage(
        fullscreenDialog: true,
        child: MobileEditPropertyScreen(
          viewId: args[MobileEditPropertyScreen.argViewId],
          field: args[MobileEditPropertyScreen.argField],
        ),
        name: MobileEditPropertyScreen.routeName,
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

      return MaterialExtendedPage(
        child: MobileCalendarEventsScreen(
          calendarBloc: args[MobileCalendarEventsScreen.calendarBlocKey],
          date: args[MobileCalendarEventsScreen.calendarDateKey],
          events: args[MobileCalendarEventsScreen.calendarEventsKey],
          rowCache: args[MobileCalendarEventsScreen.calendarRowCacheKey],
          viewId: args[MobileCalendarEventsScreen.calendarViewIdKey],
        ),
        name: MobileCalendarEventsScreen.routeName,
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
    path: MobileDocumentScreen.routeName,
    parentNavigatorKey: AppGlobals.rootNavKey,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileDocumentScreen.viewId]!;
      final title = state.uri.queryParameters[MobileDocumentScreen.viewTitle];
      final showMoreButton = bool.tryParse(
        state.uri.queryParameters[MobileDocumentScreen.viewShowMoreButton] ??
            'true',
      );
      final fixedTitle =
          state.uri.queryParameters[MobileDocumentScreen.viewFixedTitle];
      final blockId =
          state.uri.queryParameters[MobileDocumentScreen.viewBlockId];

      final selectTabs =
          state.uri.queryParameters[MobileDocumentScreen.viewSelectTabs] ?? '';
      List<PickerTabType> tabs = [];
      try {
        tabs = selectTabs
            .split('-')
            .map((e) => PickerTabType.values.byName(e))
            .toList();
      } on ArgumentError catch (e) {
        Log.error('convert selectTabs to pickerTab error', e);
      }
      if (tabs.isEmpty) {
        tabs = const [PickerTabType.emoji, PickerTabType.icon];
      }

      return MaterialExtendedPage(
        child: MobileDocumentScreen(
          id: id,
          title: title,
          showMoreButton: showMoreButton ?? true,
          fixedTitle: fixedTitle,
          blockId: blockId,
          tabs: tabs,
        ),
        name: MobileDocumentScreen.routeName,
      );
    },
  );
}

GoRoute _mobileChatScreenRoute() {
  return GoRoute(
    path: MobileChatScreen.routeName,
    parentNavigatorKey: AppGlobals.rootNavKey,
    pageBuilder: (context, state) {
      final id = state.uri.queryParameters[MobileChatScreen.viewId]!;
      final title = state.uri.queryParameters[MobileChatScreen.viewTitle];

      return MaterialExtendedPage(
        child: MobileChatScreen(id: id, title: title),
      );
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
      final arguments = state.uri.queryParameters[MobileGridScreen.viewArgs];

      return MaterialExtendedPage(
        child: MobileGridScreen(
          id: id,
          title: title,
          arguments: arguments != null ? jsonDecode(arguments) : null,
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
      return MaterialExtendedPage(
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
      return MaterialExtendedPage(
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
      var extra = state.extra as Map<String, dynamic>?;

      if (kDebugMode && extra == null) {
        extra = _dynamicValues;
      }

      if (extra == null) {
        return const MaterialExtendedPage(
          child: SizedBox.shrink(),
        );
      }

      final databaseController =
          extra[MobileRowDetailPage.argDatabaseController];
      final rowId = extra[MobileRowDetailPage.argRowId]!;

      if (kDebugMode) {
        _dynamicValues = extra;
      }

      return MaterialExtendedPage(
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
      // Every time before navigating to splash screen, we check if user is already logged in desktop. It is used to skip showing splash screen when user just changes appearance settings like theme mode.
      final userResponse = await getIt<AuthService>().getUser();
      final routeName = userResponse.fold(
        (user) => DesktopHomeScreen.routeName,
        (error) => null,
      );
      if (routeName != null && !UniversalPlatform.isMobile) return routeName;

      return null;
    },
    // Root route is SplashScreen.
    // It needs LaunchConfiguration as a parameter, so we get it from ApplicationWidget's child.
    pageBuilder: (context, state) => MaterialExtendedPage(
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
  milliseconds: RouteDurations.slow.inMilliseconds.round(),
);

// ONLY USE IN DEBUG MODE
// this is a workaround for the issue of GoRouter not supporting extra with complex types
// https://github.com/flutter/flutter/issues/137248
Map<String, dynamic> _dynamicValues = {};

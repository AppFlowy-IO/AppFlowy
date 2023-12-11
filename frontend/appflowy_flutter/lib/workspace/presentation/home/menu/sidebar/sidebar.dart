import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_top_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_trash.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_user.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home Sidebar is the left side bar of the home page.
///
/// in the sidebar, we have:
///   - user icon, user name
///   - settings
///   - scrollable document list
///   - trash
class HomeSideBar extends StatelessWidget {
  const HomeSideBar({
    super.key,
    required this.user,
    required this.workspaceSetting,
  });

  final UserProfilePB user;

  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<NotificationActionBloc>(),
        ),
        BlocProvider(
          create: (_) => MenuBloc(
            user: user,
            workspaceId: workspaceSetting.workspaceId,
          )..add(const MenuEvent.initial()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) =>
                p.lastCreatedView?.id != c.lastCreatedView?.id,
            listener: (context, state) => context.read<TabsBloc>().add(
                  TabsEvent.openPlugin(plugin: state.lastCreatedView!.plugin()),
                ),
          ),
          BlocListener<NotificationActionBloc, NotificationActionState>(
            listener: _onNotificationAction,
          ),
        ],
        child: Builder(
          builder: (context) {
            final menuState = context.watch<MenuBloc>().state;
            final favoriteState = context.watch<FavoriteBloc>().state;

            return _buildSidebar(
              context,
              menuState.views,
              favoriteState.views,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    List<ViewPB> views,
    List<ViewPB> favoriteViews,
  ) {
    const menuHorizontalInset = EdgeInsets.symmetric(horizontal: 12);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // top menu
          const Padding(
            padding: menuHorizontalInset,
            child: SidebarTopMenu(),
          ),
          // user, setting
          Padding(
            padding: menuHorizontalInset,
            child: SidebarUser(user: user, views: views),
          ),
          const VSpace(20),
          // scrollable document list
          Expanded(
            child: Padding(
              padding: menuHorizontalInset,
              child: SingleChildScrollView(
                child: SidebarFolder(
                  views: views,
                  favoriteViews: favoriteViews,
                ),
              ),
            ),
          ),
          const VSpace(10),
          // trash
          const Padding(
            padding: menuHorizontalInset,
            child: SidebarTrashButton(),
          ),
          const VSpace(10),
          // new page button
          const SidebarNewPageButton(),
        ],
      ),
    );
  }

  void _onNotificationAction(
    BuildContext context,
    NotificationActionState state,
  ) {
    final action = state.action;
    if (action != null) {
      if (action.type == ActionType.openView) {
        final view =
            context.read<MenuBloc>().state.views.findView(action.objectId);

        if (view != null) {
          context.read<TabsBloc>().openPlugin(view);

          final nodePath =
              action.arguments?[ActionArgumentKeys.nodePath.name] as int?;
          if (nodePath != null) {
            context.read<NotificationActionBloc>().add(
                  NotificationActionEvent.performAction(
                    action: action.copyWith(type: ActionType.jumpToBlock),
                  ),
                );
          }
        }
      }
    }
  }
}

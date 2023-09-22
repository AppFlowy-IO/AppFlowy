import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/local_notifications/notification_action.dart';
import 'package:appflowy/workspace/application/local_notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_top_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_trash.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_user.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:collection/collection.dart';
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
            workspace: workspaceSetting.workspace,
          )..add(const MenuEvent.initial()),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        )
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.plugin.id != c.plugin.id,
            listener: (context, state) => context
                .read<TabsBloc>()
                .add(TabsEvent.openPlugin(plugin: state.plugin)),
          ),
          BlocListener<NotificationActionBloc, NotificationActionState>(
            listener: (context, state) {
              final action = state.action;
              if (action != null) {
                switch (action.type) {
                  case ActionType.openView:
                    final view = context
                        .read<MenuBloc>()
                        .state
                        .views
                        .firstWhereOrNull((view) => action.objectId == view.id);

                    if (view != null) {
                      context.read<TabsBloc>().openPlugin(view);
                    }
                }
              }
            },
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // top menu
            const SidebarTopMenu(),
            // user, setting
            SidebarUser(user: user, views: views),
            const VSpace(20),
            // scrollable document list
            Expanded(
              child: SingleChildScrollView(
                child: SidebarFolder(
                  views: views,
                  favoriteViews: favoriteViews,
                ),
              ),
            ),
            const VSpace(10),
            // trash
            const SidebarTrashButton(),
            const VSpace(10),
            // new page button
            const Padding(
              padding: EdgeInsets.only(left: 6.0),
              child: SidebarNewPageButton(),
            ),
          ],
        ),
      ),
    );
  }
}

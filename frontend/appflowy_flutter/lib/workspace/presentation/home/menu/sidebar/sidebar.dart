import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_favorite.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_top_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_trash.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_user.dart';
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
          create: (_) => MenuBloc(
            user: user,
            workspace: workspaceSetting.workspace,
          )..add(const MenuEvent.initial()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<FavoriteBloc>()..add(const FavoriteEvent.initial()),
        )
      ],
      child: BlocConsumer<MenuBloc, MenuState>(
        builder: (context, state) => _buildSidebar(context, state),
        listenWhen: (p, c) => p.plugin.id != c.plugin.id,
        listener: (context, state) => getIt<TabsBloc>().add(
          TabsEvent.openPlugin(plugin: state.plugin),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, MenuState state) {
    final views = state.views;
    return Container(
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
            SidebarUser(user: user),
            // Favorite, Not supported yet
            const VSpace(20),
            const SingleChildScrollView(
              child: SidebarFavorite(),
            ),
            // scrollable document list
            Expanded(
              child: SingleChildScrollView(
                child: SidebarFolder(
                  views: views,
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

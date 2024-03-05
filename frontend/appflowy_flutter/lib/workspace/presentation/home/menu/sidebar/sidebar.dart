import 'dart:async';

import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_root_views_bloc.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_top_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_trash.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_user.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_workspace.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_editor/appflowy_editor.dart';
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
class HomeSideBar extends StatefulWidget {
  const HomeSideBar({
    super.key,
    required this.userProfile,
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;

  final WorkspaceSettingPB workspaceSetting;

  @override
  State<HomeSideBar> createState() => _HomeSideBarState();
}

class _HomeSideBarState extends State<HomeSideBar> {
  final _scrollController = ScrollController();
  Timer? _srollDebounce;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }

  void _onScrollChanged() {
    setState(() => isScrolling = true);

    _srollDebounce?.cancel();
    _srollDebounce =
        Timer(const Duration(milliseconds: 300), _setScrollStopped);
  }

  void _setScrollStopped() {
    if (mounted) {
      setState(() => isScrolling = false);
    }
  }

  @override
  void dispose() {
    _srollDebounce?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserWorkspaceBloc>(
      create: (_) => UserWorkspaceBloc(userProfile: widget.userProfile)
        ..add(const UserWorkspaceEvent.fetchWorkspaces()),
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        buildWhen: (previous, current) =>
            previous.currentWorkspace?.workspaceId !=
            current.currentWorkspace?.workspaceId,
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<NotificationActionBloc>(),
              ),
              BlocProvider(
                create: (_) => SidebarRootViewsBloc()
                  ..add(
                    SidebarRootViewsEvent.initial(
                      widget.userProfile,
                      state.currentWorkspace?.workspaceId ??
                          widget.workspaceSetting.workspaceId,
                    ),
                  ),
              ),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<SidebarRootViewsBloc, SidebarRootViewState>(
                  listenWhen: (p, c) =>
                      p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
                  listener: (context, state) => context.read<TabsBloc>().add(
                        TabsEvent.openPlugin(
                          plugin: state.lastCreatedRootView!.plugin(),
                        ),
                      ),
                ),
                BlocListener<NotificationActionBloc, NotificationActionState>(
                  listenWhen: (_, curr) => curr.action != null,
                  listener: _onNotificationAction,
                ),
                BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
                  listener: (context, state) {
                    context.read<SidebarRootViewsBloc>().add(
                          SidebarRootViewsEvent.reset(
                            widget.userProfile,
                            state.currentWorkspace?.workspaceId ??
                                widget.workspaceSetting.workspaceId,
                          ),
                        );
                  },
                ),
              ],
              child: Builder(
                builder: (context) {
                  final menuState = context.watch<SidebarRootViewsBloc>().state;
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
        },
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
        children: [
          // top menu
          const Padding(
            padding: menuHorizontalInset,
            child: SidebarTopMenu(),
          ),
          // user or workspace, setting
          Padding(
            padding: menuHorizontalInset,
            child: FeatureFlag.collaborativeWorkspace.isOn
                ? SidebarWorkspace(
                    userProfile: widget.userProfile,
                    views: views,
                  )
                : SidebarUser(
                    userProfile: widget.userProfile,
                    views: views,
                  ),
          ),

          const VSpace(20),
          // scrollable document list
          Expanded(
            child: Padding(
              padding: menuHorizontalInset,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: SidebarFolder(
                  views: views,
                  favoriteViews: favoriteViews,
                  isHoverEnabled: !isScrolling,
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
        final view = context
            .read<SidebarRootViewsBloc>()
            .state
            .views
            .findView(action.objectId);

        if (view != null) {
          final Map<String, dynamic> arguments = {};

          final nodePath = action.arguments?[ActionArgumentKeys.nodePath];
          if (nodePath != null) {
            arguments[PluginArgumentKeys.selection] = Selection.collapsed(
              Position(path: [nodePath]),
            );
          }

          final rowId = action.arguments?[ActionArgumentKeys.rowId];
          if (rowId != null) {
            arguments[PluginArgumentKeys.rowId] = rowId;
          }

          context.read<TabsBloc>().openPlugin(view, arguments: arguments);
        }
      }
    }
  }
}

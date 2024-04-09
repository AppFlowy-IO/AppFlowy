import 'dart:async';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/favorite/prelude.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
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
class HomeSideBar extends StatelessWidget {
  const HomeSideBar({
    super.key,
    required this.userProfile,
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;

  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    // Workspace Bloc: control the current workspace
    //   |
    //   +-- Workspace Menu
    //   |    |
    //   |    +-- Workspace List: control to switch workspace
    //   |    |
    //   |    +-- Workspace Settings
    //   |    |
    //   |    +-- Notification Center
    //   |
    //   +-- Favorite Section
    //   |
    //   +-- Public Or Private Section: control the sections of the workspace
    //   |
    //   +-- Trash Section
    return BlocProvider<UserWorkspaceBloc>(
      create: (_) => UserWorkspaceBloc(userProfile: userProfile)
        ..add(
          const UserWorkspaceEvent.initial(),
        ),
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        // Rebuild the whole sidebar when the current workspace changes
        buildWhen: (previous, current) =>
            previous.currentWorkspace?.workspaceId !=
            current.currentWorkspace?.workspaceId,
        builder: (context, state) {
          if (state.currentWorkspace == null) {
            return const SizedBox.shrink();
          }
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => getIt<NotificationActionBloc>(),
              ),
              BlocProvider(
                create: (_) => SidebarSectionsBloc()
                  ..add(
                    SidebarSectionsEvent.initial(
                      userProfile,
                      state.currentWorkspace?.workspaceId ??
                          workspaceSetting.workspaceId,
                    ),
                  ),
              ),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<SidebarSectionsBloc, SidebarSectionsState>(
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
                    final actionType = state.actionResult?.actionType;

                    if (actionType == UserWorkspaceActionType.create ||
                        actionType == UserWorkspaceActionType.delete ||
                        actionType == UserWorkspaceActionType.open) {
                      context.read<SidebarSectionsBloc>().add(
                            SidebarSectionsEvent.reload(
                              userProfile,
                              state.currentWorkspace?.workspaceId ??
                                  workspaceSetting.workspaceId,
                            ),
                          );
                      context.read<FavoriteBloc>().add(
                            const FavoriteEvent.fetchFavorites(),
                          );
                    }
                  },
                ),
              ],
              child: _Sidebar(userProfile: userProfile),
            ),
          );
        },
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
            .read<SidebarSectionsBloc>()
            .state
            .section
            .publicViews
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

class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  final _scrollController = ScrollController();
  Timer? _scrollDebounce;
  bool isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child:
                // if the workspaces are empty, show the user profile instead
                context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn &&
                        context
                            .read<UserWorkspaceBloc>()
                            .state
                            .workspaces
                            .isNotEmpty
                    ? SidebarWorkspace(
                        userProfile: widget.userProfile,
                      )
                    : SidebarUser(
                        userProfile: widget.userProfile,
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
                  userProfile: widget.userProfile,
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

  void _onScrollChanged() {
    setState(() => isScrolling = true);

    _scrollDebounce?.cancel();
    _scrollDebounce =
        Timer(const Duration(milliseconds: 300), _setScrollStopped);
  }

  void _setScrollStopped() {
    if (mounted) {
      setState(() => isScrolling = false);
    }
  }
}

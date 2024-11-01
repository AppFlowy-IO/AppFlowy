import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/favorite_folder/favorite_space.dart';
import 'package:appflowy/mobile/presentation/home/home_space/home_space.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/recent_space.dart';
import 'package:appflowy/mobile/presentation/home/tab/_tab_bar.dart';
import 'package:appflowy/mobile/presentation/home/tab/space_order_bloc.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/workspace/invite_members_screen.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'ai_bubble_button.dart';

final ValueNotifier<int> mobileCreateNewAIChatNotifier = ValueNotifier(0);

class MobileSpaceTab extends StatefulWidget {
  const MobileSpaceTab({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<MobileSpaceTab> createState() => _MobileSpaceTabState();
}

class _MobileSpaceTabState extends State<MobileSpaceTab>
    with SingleTickerProviderStateMixin {
  TabController? tabController;

  @override
  void initState() {
    super.initState();

    mobileCreateNewPageNotifier.addListener(_createNewDocument);
    mobileCreateNewAIChatNotifier.addListener(_createNewAIChat);
    mobileLeaveWorkspaceNotifier.addListener(_leaveWorkspace);
  }

  @override
  void dispose() {
    tabController?.removeListener(_onTabChange);
    tabController?.dispose();

    mobileCreateNewPageNotifier.removeListener(_createNewDocument);
    mobileCreateNewAIChatNotifier.removeListener(_createNewAIChat);
    mobileLeaveWorkspaceNotifier.removeListener(_leaveWorkspace);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: widget.userProfile,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SpaceBloc, SpaceState>(
            listenWhen: (p, c) =>
                p.lastCreatedPage?.id != c.lastCreatedPage?.id,
            listener: (context, state) {
              final lastCreatedPage = state.lastCreatedPage;
              if (lastCreatedPage != null) {
                context.pushView(lastCreatedPage);
              }
            },
          ),
          BlocListener<SidebarSectionsBloc, SidebarSectionsState>(
            listenWhen: (p, c) =>
                p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
            listener: (context, state) {
              final lastCreatedPage = state.lastCreatedRootView;
              if (lastCreatedPage != null) {
                context.pushView(lastCreatedPage);
              }
            },
          ),
        ],
        child: BlocBuilder<SpaceOrderBloc, SpaceOrderState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const SizedBox.shrink();
            }

            _initTabController(state);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MobileSpaceTabBar(
                  tabController: tabController!,
                  tabs: state.tabsOrder,
                  onReorder: (from, to) {
                    context.read<SpaceOrderBloc>().add(
                          SpaceOrderEvent.reorder(from, to),
                        );
                  },
                ),
                const HSpace(12.0),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: _buildTabs(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _initTabController(SpaceOrderState state) {
    if (tabController != null) {
      return;
    }
    tabController = TabController(
      length: state.tabsOrder.length,
      vsync: this,
      initialIndex: state.tabsOrder.indexOf(state.defaultTab),
    );
    tabController?.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (tabController == null) {
      return;
    }
    context
        .read<SpaceOrderBloc>()
        .add(SpaceOrderEvent.open(tabController!.index));
  }

  List<Widget> _buildTabs(SpaceOrderState state) {
    return state.tabsOrder.map((tab) {
      switch (tab) {
        case MobileSpaceTabType.recent:
          return const MobileRecentSpace();
        case MobileSpaceTabType.spaces:
          return Stack(
            children: [
              MobileHomeSpace(userProfile: widget.userProfile),
              // only show ai chat button for cloud user
              if (widget.userProfile.authenticator ==
                  AuthenticatorPB.AppFlowyCloud)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  left: 20,
                  right: 20,
                  child: const FloatingAIEntry(),
                ),
            ],
          );
        case MobileSpaceTabType.favorites:
          return MobileFavoriteSpace(userProfile: widget.userProfile);
        default:
          throw Exception('Unknown tab type: $tab');
      }
    }).toList();
  }

  // quick create new page when clicking the add button in navigation bar
  void _createNewDocument() => _createNewPage(ViewLayoutPB.Document);

  void _createNewAIChat() => _createNewPage(ViewLayoutPB.Chat);

  void _createNewPage(ViewLayoutPB layout) {
    if (context.read<SpaceBloc>().state.spaces.isNotEmpty) {
      context.read<SpaceBloc>().add(
            SpaceEvent.createPage(
              name: layout.defaultName,
              layout: layout,
            ),
          );
    } else if (layout == ViewLayoutPB.Document) {
      // only support create document in section
      context.read<SidebarSectionsBloc>().add(
            SidebarSectionsEvent.createRootViewInSection(
              name: layout.defaultName,
              index: 0,
              viewSection: FolderSpaceType.public.toViewSectionPB,
            ),
          );
    }
  }

  void _leaveWorkspace() {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId;
    if (workspaceId == null) {
      return Log.error('Workspace ID is null');
    }
    context
        .read<UserWorkspaceBloc>()
        .add(UserWorkspaceEvent.leaveWorkspace(workspaceId));
  }
}

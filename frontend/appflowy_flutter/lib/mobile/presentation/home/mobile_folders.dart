import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

// Contains Public And Private Sections
class MobileFolders extends StatelessWidget {
  const MobileFolders({
    super.key,
    required this.user,
    required this.workspaceId,
    required this.showFavorite,
  });

  final UserProfilePB user;
  final String workspaceId;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SidebarSectionsBloc()
            ..add(SidebarSectionsEvent.initial(user, workspaceId)),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
        ),
        BlocProvider(
          create: (_) => SpaceBloc()
            ..add(SpaceEvent.initial(user, workspaceId, openFirstPage: false)),
        ),
      ],
      child: BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
        listener: (context, state) {
          context.read<SidebarSectionsBloc>().add(
                SidebarSectionsEvent.initial(
                  user,
                  state.currentWorkspace?.workspaceId ?? workspaceId,
                ),
              );
          context.read<SpaceBloc>().add(
                SpaceEvent.reset(
                  user,
                  state.currentWorkspace?.workspaceId ?? workspaceId,
                ),
              );
        },
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
          child: BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
            builder: (context, state) {
              return SlidableAutoCloseBehavior(
                child: Column(
                  children: [
                    ..._buildSpaceOrSection(context, state),
                    const VSpace(4.0),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: HomeSpaceViewSizes.mHorizontalPadding,
                      ),
                      child: _TrashButton(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpaceOrSection(
    BuildContext context,
    SidebarSectionsState state,
  ) {
    if (context.watch<SpaceBloc>().state.spaces.isNotEmpty) {
      return [
        const MobileSpace(),
      ];
    }

    if (context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn) {
      return [
        MobileSectionFolder(
          title: LocaleKeys.sideBar_workspace.tr(),
          spaceType: FolderSpaceType.public,
          views: state.section.publicViews,
        ),
        const VSpace(8.0),
        MobileSectionFolder(
          title: LocaleKeys.sideBar_private.tr(),
          spaceType: FolderSpaceType.private,
          views: state.section.privateViews,
        ),
      ];
    }

    return [
      MobileSectionFolder(
        title: LocaleKeys.sideBar_personal.tr(),
        spaceType: FolderSpaceType.public,
        views: state.section.publicViews,
      ),
    ];
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FlowyButton(
        expand: true,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2.0),
        leftIcon: const FlowySvg(
          FlowySvgs.m_delete_s,
        ),
        leftIconSize: const Size.square(18),
        iconPadding: 10.0,
        text: FlowyText.regular(
          LocaleKeys.trash_text.tr(),
          fontSize: 16.0,
        ),
        onTap: () => context.push(MobileHomeTrashPage.routeName),
      ),
    );
  }
}

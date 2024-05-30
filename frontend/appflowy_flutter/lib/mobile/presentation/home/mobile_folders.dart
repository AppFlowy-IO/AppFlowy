import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
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
            ..add(
              SidebarSectionsEvent.initial(
                user,
                workspaceId,
              ),
            ),
        ),
        BlocProvider(
          create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
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
        },
        child: BlocConsumer<SidebarSectionsBloc, SidebarSectionsState>(
          listenWhen: (p, c) =>
              p.lastCreatedRootView?.id != c.lastCreatedRootView?.id,
          listener: (context, state) {
            final lastCreatedRootView = state.lastCreatedRootView;
            if (lastCreatedRootView != null) {
              context.pushView(lastCreatedRootView);
            }
          },
          builder: (context, state) {
            final isCollaborativeWorkspace =
                context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn;
            return SlidableAutoCloseBehavior(
              child: Column(
                children: [
                  ...isCollaborativeWorkspace
                      ? [
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
                        ]
                      : [
                          MobileSectionFolder(
                            title: LocaleKeys.sideBar_personal.tr(),
                            spaceType: FolderSpaceType.public,
                            views: state.section.publicViews,
                          ),
                        ],
                  const VSpace(4.0),
                  const _TrashButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
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
        margin: const EdgeInsets.symmetric(vertical: 8),
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

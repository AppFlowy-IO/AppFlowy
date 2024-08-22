import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return BlocListener<UserWorkspaceBloc, UserWorkspaceState>(
      listenWhen: (previous, current) =>
          previous.currentWorkspace?.workspaceId !=
          current.currentWorkspace?.workspaceId,
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
      child: const _MobileFolder(),
    );
  }
}

class _MobileFolder extends StatefulWidget {
  const _MobileFolder();

  @override
  State<_MobileFolder> createState() => _MobileFolderState();
}

class _MobileFolderState extends State<_MobileFolder> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
      builder: (context, state) {
        return SlidableAutoCloseBehavior(
          child: Column(
            children: [
              ..._buildSpaceOrSection(context, state),
              const VSpace(80.0),
            ],
          ),
        );
      },
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

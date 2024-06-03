import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_section_folder.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    this.isHoverEnabled = true,
    required this.userProfile,
  });

  final bool isHoverEnabled;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    const sectionPadding = 16.0;
    return ValueListenableBuilder(
      valueListenable: getIt<MenuSharedState>().notifier,
      builder: (context, value, child) {
        return Column(
          children: [
            // favorite
            BlocBuilder<FavoriteBloc, FavoriteState>(
              builder: (context, state) {
                if (state.views.isEmpty) {
                  return const SizedBox.shrink();
                }
                return FavoriteFolder(
                  views: state.views.map((e) => e.item).toList(),
                );
              },
            ),
            // public or private
            BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
              builder: (context, state) {
                // only show public and private section if the workspace is collaborative and not local
                final isCollaborativeWorkspace =
                    context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn;

                // only show public and private section if the workspace is collaborative
                return Column(
                  children: isCollaborativeWorkspace
                      ? [
                          // public
                          const VSpace(sectionPadding),
                          PublicSectionFolder(views: state.section.publicViews),

                          // private
                          const VSpace(sectionPadding),
                          PrivateSectionFolder(
                            views: state.section.privateViews,
                          ),
                        ]
                      : [
                          // personal
                          const VSpace(sectionPadding),
                          PersonalSectionFolder(
                            views: state.section.publicViews,
                          ),
                        ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class PrivateSectionFolder extends SectionFolder {
  PrivateSectionFolder({super.key, required super.views})
      : super(
          title: LocaleKeys.sideBar_private.tr(),
          spaceType: FolderSpaceType.private,
          expandButtonTooltip: LocaleKeys.sideBar_clickToHidePrivate.tr(),
          addButtonTooltip: LocaleKeys.sideBar_addAPageToPrivate.tr(),
        );
}

class PublicSectionFolder extends SectionFolder {
  PublicSectionFolder({super.key, required super.views})
      : super(
          title: LocaleKeys.sideBar_workspace.tr(),
          spaceType: FolderSpaceType.public,
          expandButtonTooltip: LocaleKeys.sideBar_clickToHideWorkspace.tr(),
          addButtonTooltip: LocaleKeys.sideBar_addAPageToWorkspace.tr(),
        );
}

class PersonalSectionFolder extends SectionFolder {
  PersonalSectionFolder({super.key, required super.views})
      : super(
          title: LocaleKeys.sideBar_personal.tr(),
          spaceType: FolderSpaceType.public,
          expandButtonTooltip: LocaleKeys.sideBar_clickToHidePersonal.tr(),
          addButtonTooltip: LocaleKeys.sideBar_addAPage.tr(),
        );
}

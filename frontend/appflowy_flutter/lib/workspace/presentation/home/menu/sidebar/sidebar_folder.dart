import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_section_folder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    this.isHoverEnabled = true,
  });

  final bool isHoverEnabled;

  @override
  Widget build(BuildContext context) {
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FavoriteFolder(
                    // remove the duplicate views
                    views: state.views,
                  ),
                );
              },
            ),
            // public or private
            BlocBuilder<SidebarSectionsBloc, SidebarSectionsState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // only show public section if the workspace is collaborative
                    if (context
                        .read<UserWorkspaceBloc>()
                        .state
                        .isCollaborativeWorkspace) ...[
                      // public
                      const VSpace(10),
                      SectionFolder(
                        title: LocaleKeys.sideBar_public.tr(),
                        categoryType: FolderCategoryType.public,
                        views: state.section.publicViews,
                      ),
                    ],

                    // private
                    const VSpace(10),
                    SectionFolder(
                      title: LocaleKeys.sideBar_private.tr(),
                      categoryType: FolderCategoryType.private,
                      views: state.section.privateViews,
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

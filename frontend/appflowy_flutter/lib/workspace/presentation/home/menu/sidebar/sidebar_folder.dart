import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/private_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/public_folder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    required this.views,
    required this.favoriteViews,
    this.isHoverEnabled = true,
  });

  final List<ViewPB> views;
  final List<ViewPB> favoriteViews;
  final bool isHoverEnabled;

  @override
  Widget build(BuildContext context) {
    // check if there is any duplicate views
    final views = this.views.toSet().toList();
    final favoriteViews = this.favoriteViews.toSet().toList();
    assert(views.length == this.views.length);
    assert(favoriteViews.length == favoriteViews.length);

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
                      const SizedBox(height: 10),
                      PublicFolder(
                        views: state.publicViews,
                      ),
                    ],

                    // private
                    const SizedBox(height: 10),
                    PrivateFolder(
                      views: state.privateViews,
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

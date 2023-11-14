import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/favorite_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/personal_folder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SidebarFolder extends StatelessWidget {
  const SidebarFolder({
    super.key,
    required this.views,
    required this.favoriteViews,
  });

  final List<ViewPB> views;
  final List<ViewPB> favoriteViews;

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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // favorite
            if (favoriteViews.isNotEmpty) ...[
              FavoriteFolder(
                // remove the duplicate views
                views: favoriteViews,
              ),
              const VSpace(10),
            ],
            // personal
            PersonalFolder(views: views),
          ],
        );
      },
    );
  }
}

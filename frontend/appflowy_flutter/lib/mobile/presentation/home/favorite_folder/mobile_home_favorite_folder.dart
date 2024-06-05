import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/default_mobile_action_pane.dart';
import 'package:appflowy/mobile/presentation/home/favorite_folder/mobile_home_favorite_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFavoriteFolder extends StatelessWidget {
  const MobileFavoriteFolder({
    super.key,
    required this.views,
    this.showHeader = true,
    this.forceExpanded = false,
  });

  final bool showHeader;
  final bool forceExpanded;
  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderSpaceType.favorite)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              if (showHeader) ...[
                MobileFavoriteFolderHeader(
                  isExpanded: context.read<FolderBloc>().state.isExpanded,
                  onPressed: () => context
                      .read<FolderBloc>()
                      .add(const FolderEvent.expandOrUnExpand()),
                  onAdded: () => context.read<FolderBloc>().add(
                        const FolderEvent.expandOrUnExpand(isExpanded: true),
                      ),
                ),
                const VSpace(8.0),
                const Divider(
                  height: 1,
                ),
              ],
              if (forceExpanded || state.isExpanded)
                ...views.map(
                  (view) => MobileViewItem(
                    key: ValueKey(
                      '${FolderSpaceType.favorite.name} ${view.id}',
                    ),
                    spaceType: FolderSpaceType.favorite,
                    isDraggable: false,
                    isFirstChild: view.id == views.first.id,
                    isFeedback: false,
                    view: view,
                    level: 0,
                    onSelected: context.pushView,
                    endActionPane: (context) => buildEndActionPane(
                      context,
                      [
                        view.isFavorite
                            ? MobilePaneActionType.removeFromFavorites
                            : MobilePaneActionType.addToFavorites,
                        MobilePaneActionType.more,
                      ],
                      spaceType: FolderSpaceType.favorite,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

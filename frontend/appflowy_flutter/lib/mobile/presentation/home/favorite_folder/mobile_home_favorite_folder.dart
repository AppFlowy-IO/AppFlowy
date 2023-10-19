import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/favourite_folder/mobile_home_favorite_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class MobileFavoriteFolder extends StatelessWidget {
  const MobileFavoriteFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderCategoryType.favorite)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              MobileFavoriteFolderHeader(
                isExpanded: context.read<FolderBloc>().state.isExpanded,
                onPressed: () => context
                    .read<FolderBloc>()
                    .add(const FolderEvent.expandOrUnExpand()),
                onAdded: () => context
                    .read<FolderBloc>()
                    .add(const FolderEvent.expandOrUnExpand(isExpanded: true)),
              ),
              const VSpace(8.0),
              const Divider(
                height: 1,
              ),
              if (state.isExpanded)
                ...views.map(
                  (view) => MobileViewItem(
                    key: ValueKey(
                      '${FolderCategoryType.favorite.name} ${view.id}',
                    ),
                    categoryType: FolderCategoryType.favorite,
                    isDraggable: false,
                    isFirstChild: view.id == views.first.id,
                    isFeedback: false,
                    view: view,
                    level: 0,
                    onSelected: (view) async {
                      await context.pushView(view);
                    },
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      dismissible: DismissiblePane(
                        onDismissed: () {
                          HapticFeedback.mediumImpact();
                          context
                              .read<FavoriteBloc>()
                              .add(FavoriteEvent.toggle(view));
                        },
                      ),
                      children: [
                        MobileSlideActionButton(
                          backgroundColor: Colors.red,
                          svg: FlowySvgs.unfavorite_s,
                          onPressed: (context) => context
                              .read<FavoriteBloc>()
                              .add(FavoriteEvent.toggle(view)),
                        ),
                      ],
                    ),
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}

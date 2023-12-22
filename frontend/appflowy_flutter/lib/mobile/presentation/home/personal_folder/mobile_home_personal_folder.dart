import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/default_mobile_action_pane.dart';
import 'package:appflowy/mobile/presentation/home/personal_folder/mobile_home_personal_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobilePersonalFolder extends StatelessWidget {
  const MobilePersonalFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderCategoryType.personal)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              MobilePersonalFolderHeader(
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
              if (state.isExpanded)
                ...views.map(
                  (view) => MobileViewItem(
                    key: ValueKey(
                      '${FolderCategoryType.personal.name} ${view.id}',
                    ),
                    isDraggable: true,
                    categoryType: FolderCategoryType.personal,
                    isFirstChild: view.id == views.first.id,
                    view: view,
                    level: 0,
                    leftPadding: 16,
                    isFeedback: false,
                    onSelected: (view) async {
                      await context.pushView(view);
                    },
                    endActionPane: (context) {
                      final view = context.read<ViewBloc>().state.view;
                      return buildEndActionPane(context, [
                        MobilePaneActionType.delete,
                        view.isFavorite
                            ? MobilePaneActionType.removeFromFavorites
                            : MobilePaneActionType.addToFavorites,
                        MobilePaneActionType.more,
                      ]);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

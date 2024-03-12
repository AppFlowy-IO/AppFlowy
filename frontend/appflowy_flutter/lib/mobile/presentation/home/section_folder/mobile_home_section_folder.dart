import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/default_mobile_action_pane.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSectionFolder extends StatelessWidget {
  const MobileSectionFolder({
    super.key,
    required this.title,
    required this.views,
  });

  final String title;
  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderCategoryType.private)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              MobileSectionFolderHeader(
                title: title,
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
                      '${FolderCategoryType.private.name} ${view.id}',
                    ),
                    categoryType: FolderCategoryType.private,
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

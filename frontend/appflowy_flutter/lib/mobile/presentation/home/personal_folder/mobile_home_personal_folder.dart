import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/home/personal_folder/mobile_home_personal_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
                    isDraggable: false,
                    categoryType: FolderCategoryType.personal,
                    isFirstChild: view.id == views.first.id,
                    view: view,
                    level: 0,
                    leftPadding: 16,
                    isFeedback: false,
                    onSelected: (view) async {
                      await context.pushView(view);
                    },
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        MobileSlideActionButton(
                          backgroundColor: Colors.red,
                          svg: FlowySvgs.delete_s,
                          size: 30.0,
                          onPressed: (context) => context
                              .read<ViewBloc>()
                              .add(const ViewEvent.delete()),
                        ),
                        MobileSlideActionButton(
                          backgroundColor: Colors.orange,
                          svg: FlowySvgs.m_favorite_unselected_lg,
                          size: 36.0,
                          onPressed: (context) => context
                              .read<FavoriteBloc>()
                              .add(FavoriteEvent.toggle(view)),
                        ),
                        MobileSlideActionButton(
                          backgroundColor: Colors.grey,
                          svg: FlowySvgs.three_dots_vertical_s,
                          size: 28.0,
                          onPressed: (context) {
                            // TODO: implement
                          },
                        )
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

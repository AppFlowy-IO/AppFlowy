import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/default_mobile_action_pane.dart';
import 'package:appflowy/mobile/presentation/home/section_folder/mobile_home_section_folder_header.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSectionFolder extends StatelessWidget {
  const MobileSectionFolder({
    super.key,
    required this.title,
    required this.views,
    required this.spaceType,
  });

  final String title;
  final List<ViewPB> views;
  final FolderSpaceType spaceType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: spaceType)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              SizedBox(
                height: HomeSpaceViewSizes.mobileViewHeight,
                child: MobileSectionFolderHeader(
                  title: title,
                  isExpanded: context.read<FolderBloc>().state.isExpanded,
                  onPressed: () => context
                      .read<FolderBloc>()
                      .add(const FolderEvent.expandOrUnExpand()),
                  onAdded: () {
                    context.read<SidebarSectionsBloc>().add(
                          SidebarSectionsEvent.createRootViewInSection(
                            name: LocaleKeys.menuAppHeader_defaultNewPageName
                                .tr(),
                            index: 0,
                            viewSection: spaceType.toViewSectionPB,
                          ),
                        );
                    context.read<FolderBloc>().add(
                          const FolderEvent.expandOrUnExpand(isExpanded: true),
                        );
                  },
                ),
              ),
              if (state.isExpanded)
                ...views.map(
                  (view) => MobileViewItem(
                    key: ValueKey(
                      '${FolderSpaceType.private.name} ${view.id}',
                    ),
                    spaceType: spaceType,
                    isFirstChild: view.id == views.first.id,
                    view: view,
                    level: 0,
                    leftPadding: HomeSpaceViewSizes.leftPadding,
                    isFeedback: false,
                    onSelected: context.pushView,
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

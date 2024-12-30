import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
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
                height: HomeSpaceViewSizes.mViewHeight,
                child: MobileSectionFolderHeader(
                  title: title,
                  isExpanded: context.read<FolderBloc>().state.isExpanded,
                  onPressed: () => context
                      .read<FolderBloc>()
                      .add(const FolderEvent.expandOrUnExpand()),
                  onAdded: () => _createNewPage(context),
                ),
              ),
              if (state.isExpanded)
                Padding(
                  padding: const EdgeInsets.only(
                    left: HomeSpaceViewSizes.leftPadding,
                  ),
                  child: _Pages(
                    views: views,
                    spaceType: spaceType,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _createNewPage(BuildContext context) {
    context.read<SidebarSectionsBloc>().add(
          SidebarSectionsEvent.createRootViewInSection(
            name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
            index: 0,
            viewSection: spaceType.toViewSectionPB,
          ),
        );
    context.read<FolderBloc>().add(
          const FolderEvent.expandOrUnExpand(isExpanded: true),
        );
  }
}

class _Pages extends StatelessWidget {
  const _Pages({
    required this.views,
    required this.spaceType,
  });

  final List<ViewPB> views;
  final FolderSpaceType spaceType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: views
          .map(
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
                return buildEndActionPane(
                  context,
                  [
                    MobilePaneActionType.more,
                    if (view.layout == ViewLayoutPB.Document)
                      MobilePaneActionType.add,
                  ],
                  spaceType: spaceType,
                  needSpace: false,
                  spaceRatio: 5,
                );
              },
            ),
          )
          .toList(),
    );
  }
}

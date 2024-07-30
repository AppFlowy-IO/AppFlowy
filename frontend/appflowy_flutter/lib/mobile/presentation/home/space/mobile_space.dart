import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space_header.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space_menu.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_view_item.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSpace extends StatefulWidget {
  const MobileSpace({super.key});

  @override
  State<MobileSpace> createState() => _MobileSpaceState();
}

class _MobileSpaceState extends State<MobileSpace> {
  @override
  void initState() {
    super.initState();
    createNewPageNotifier.addListener(_createNewPage);
  }

  @override
  void dispose() {
    createNewPageNotifier.removeListener(_createNewPage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        if (state.spaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final currentSpace = state.currentSpace ?? state.spaces.first;

        return Column(
          children: [
            MobileSpaceHeader(
              isExpanded: state.isExpanded,
              space: currentSpace,
              onAdded: () => _showCreatePageMenu(currentSpace),
              onPressed: () => _showSpaceMenu(context),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: HomeSpaceViewSizes.mHorizontalPadding,
              ),
              child: _Pages(
                key: ValueKey(currentSpace.id),
                space: currentSpace,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSpaceMenu(BuildContext context) {
    showMobileBottomSheet(
      context,
      showDivider: false,
      showHeader: true,
      showDragHandle: true,
      showCloseButton: true,
      showDoneButton: true,
      useRootNavigator: true,
      title: LocaleKeys.space_title.tr(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<SpaceBloc>(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: MobileSpaceMenu(),
          ),
        );
      },
    );
  }

  void _createNewPage() {
    context.read<SpaceBloc>().add(
          SpaceEvent.createPage(
            name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
            layout: ViewLayoutPB.Document,
          ),
        );
  }

  void _showCreatePageMenu(ViewPB space) {
    final title = space.name;
    showMobileBottomSheet(
      context,
      showHeader: true,
      title: title,
      showDragHandle: true,
      showCloseButton: true,
      useRootNavigator: true,
      showDivider: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return AddNewPageWidgetBottomSheet(
          view: space,
          onAction: (layout) {
            Navigator.of(sheetContext).pop();
            context.read<SpaceBloc>().add(
                  SpaceEvent.createPage(
                    name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                    layout: layout,
                    index: 0,
                  ),
                );
            context.read<SpaceBloc>().add(
                  SpaceEvent.expand(space, true),
                );
          },
        );
      },
    );
  }
}

class _Pages extends StatelessWidget {
  const _Pages({
    super.key,
    required this.space,
  });

  final ViewPB space;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ViewBloc(view: space)..add(const ViewEvent.initial()),
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          final spaceType = space.spacePermission == SpacePermission.publicToAll
              ? FolderSpaceType.public
              : FolderSpaceType.private;
          return Column(
            children: state.view.childViews
                .map(
                  (view) => MobileViewItem(
                    key: ValueKey(
                      '${space.id} ${view.id}',
                    ),
                    spaceType: spaceType,
                    isFirstChild: view.id == state.view.childViews.first.id,
                    view: view,
                    level: 0,
                    leftPadding: HomeSpaceViewSizes.leftPadding,
                    isFeedback: false,
                    onSelected: context.pushView,
                    endActionPane: (context) {
                      final view = context.read<ViewBloc>().state.view;
                      final actions = [
                        MobilePaneActionType.more,
                        if (view.layout == ViewLayoutPB.Document)
                          MobilePaneActionType.add,
                      ];
                      return buildEndActionPane(
                        context,
                        actions,
                        spaceType: spaceType,
                        spaceRatio: actions.length == 1 ? 3 : 4,
                      );
                    },
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

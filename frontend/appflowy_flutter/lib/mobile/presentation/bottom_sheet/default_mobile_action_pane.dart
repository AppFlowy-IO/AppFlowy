import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/shared/mobile_page_card.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum MobilePaneActionType {
  delete,
  addToFavorites,
  removeFromFavorites,
  more,
  add;

  MobileSlideActionButton actionButton(
    BuildContext context, {
    MobilePageCardType? cardType,
    FolderSpaceType? spaceType,
  }) {
    switch (this) {
      case MobilePaneActionType.delete:
        return MobileSlideActionButton(
          backgroundColor: Colors.red,
          svg: FlowySvgs.delete_s,
          size: 30.0,
          onPressed: (context) =>
              context.read<ViewBloc>().add(const ViewEvent.delete()),
        );
      case MobilePaneActionType.removeFromFavorites:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFFFA217F),
          svg: FlowySvgs.favorite_section_remove_from_favorite_s,
          size: 24.0,
          onPressed: (context) => context
              .read<FavoriteBloc>()
              .add(FavoriteEvent.toggle(context.read<ViewBloc>().view)),
        );
      case MobilePaneActionType.addToFavorites:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFF00C8FF),
          svg: FlowySvgs.favorite_s,
          size: 24.0,
          onPressed: (context) => context
              .read<FavoriteBloc>()
              .add(FavoriteEvent.toggle(context.read<ViewBloc>().view)),
        );
      case MobilePaneActionType.add:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFF00C8FF),
          svg: FlowySvgs.add_m,
          size: 28.0,
          onPressed: (context) {
            final viewBloc = context.read<ViewBloc>();
            final view = viewBloc.state.view;
            final title = view.name;
            showMobileBottomSheet(
              context,
              showHeader: true,
              title: title,
              showDragHandle: true,
              showCloseButton: true,
              useRootNavigator: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              builder: (sheetContext) {
                return AddNewPageWidgetBottomSheet(
                  view: view,
                  onAction: (layout) {
                    Navigator.of(sheetContext).pop();
                    viewBloc.add(
                      ViewEvent.createView(
                        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                        layout,
                        section: spaceType!.toViewSectionPB,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      case MobilePaneActionType.more:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xE5515563),
          svg: FlowySvgs.three_dots_s,
          size: 24.0,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
          onPressed: (context) {
            final viewBloc = context.read<ViewBloc>();
            final favoriteBloc = context.read<FavoriteBloc>();
            final recentViewsBloc = context.read<RecentViewsBloc?>();
            showMobileBottomSheet(
              context,
              showDragHandle: true,
              showDivider: false,
              useRootNavigator: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: viewBloc),
                    BlocProvider.value(value: favoriteBloc),
                    if (recentViewsBloc != null)
                      BlocProvider.value(value: recentViewsBloc),
                  ],
                  child: BlocBuilder<ViewBloc, ViewState>(
                    builder: (context, state) {
                      return MobileViewItemBottomSheet(
                        view: viewBloc.state.view,
                        actions: _buildActions(state.view, cardType: cardType),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
    }
  }

  List<MobileViewItemBottomSheetBodyAction> _buildActions(
    ViewPB view, {
    MobilePageCardType? cardType,
  }) {
    final isFavorite = view.isFavorite;

    if (cardType != null) {
      switch (cardType) {
        case MobilePageCardType.recent:
          return [
            isFavorite
                ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
                : MobileViewItemBottomSheetBodyAction.addToFavorites,
            MobileViewItemBottomSheetBodyAction.divider,
            if (view.layout != ViewLayoutPB.Chat)
              MobileViewItemBottomSheetBodyAction.duplicate,
            MobileViewItemBottomSheetBodyAction.divider,
            MobileViewItemBottomSheetBodyAction.removeFromRecent,
          ];
        case MobilePageCardType.favorite:
          return [
            isFavorite
                ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
                : MobileViewItemBottomSheetBodyAction.addToFavorites,
            MobileViewItemBottomSheetBodyAction.divider,
            MobileViewItemBottomSheetBodyAction.duplicate,
          ];
      }
    }

    return [
      isFavorite
          ? MobileViewItemBottomSheetBodyAction.removeFromFavorites
          : MobileViewItemBottomSheetBodyAction.addToFavorites,
      MobileViewItemBottomSheetBodyAction.divider,
      MobileViewItemBottomSheetBodyAction.rename,
      if (view.layout != ViewLayoutPB.Chat)
        MobileViewItemBottomSheetBodyAction.duplicate,
      MobileViewItemBottomSheetBodyAction.divider,
      MobileViewItemBottomSheetBodyAction.delete,
    ];
  }
}

ActionPane buildEndActionPane(
  BuildContext context,
  List<MobilePaneActionType> actions, {
  bool needSpace = true,
  MobilePageCardType? cardType,
  FolderSpaceType? spaceType,
}) {
  return ActionPane(
    motion: const ScrollMotion(),
    extentRatio: actions.length / 5,
    children: [
      if (needSpace) const HSpace(20),
      ...actions.map(
        (action) => action.actionButton(
          context,
          spaceType: spaceType,
          cardType: cardType,
        ),
      ),
    ],
  );
}

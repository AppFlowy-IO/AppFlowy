import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

enum MobilePaneActionType {
  delete,
  addToFavorites,
  removeFromFavorites,
  more;

  MobileSlideActionButton actionButton(
    BuildContext context,
  ) {
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
          backgroundColor: Colors.orange,
          svg: FlowySvgs.favorite_s,
          onPressed: (context) => context
              .read<FavoriteBloc>()
              .add(FavoriteEvent.toggle(context.read<ViewBloc>().view)),
        );
      case MobilePaneActionType.addToFavorites:
        return MobileSlideActionButton(
          backgroundColor: Colors.orange,
          svg: FlowySvgs.m_favorite_unselected_lg,
          size: 34.0,
          onPressed: (context) => context
              .read<FavoriteBloc>()
              .add(FavoriteEvent.toggle(context.read<ViewBloc>().view)),
        );
      case MobilePaneActionType.more:
        return MobileSlideActionButton(
          backgroundColor: Colors.grey,
          svg: FlowySvgs.three_dots_vertical_s,
          size: 28.0,
          onPressed: (context) {
            final viewBloc = context.read<ViewBloc>();
            final favoriteBloc = context.read<FavoriteBloc>();
            showMobileBottomSheet(
              context,
              showDragHandle: true,
              showDivider: false,
              backgroundColor: Theme.of(context).colorScheme.background,
              useRootNavigator: true,
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: viewBloc),
                    BlocProvider.value(value: favoriteBloc),
                  ],
                  child: BlocBuilder<ViewBloc, ViewState>(
                    builder: (context, state) {
                      return MobileViewItemBottomSheet(
                        view: viewBloc.state.view,
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
}

ActionPane buildEndActionPane(
  BuildContext context,
  List<MobilePaneActionType> actions,
) {
  return ActionPane(
    motion: const ScrollMotion(),
    extentRatio: actions.length / 5,
    children: actions
        .map(
          (action) => action.actionButton(context),
        )
        .toList(),
  );
}

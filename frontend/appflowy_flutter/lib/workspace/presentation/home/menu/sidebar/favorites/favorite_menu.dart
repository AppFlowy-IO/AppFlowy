import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_more_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _kHorizontalPadding = 10.0;
const double _kVerticalPadding = 10.0;

class FavoriteMenu extends StatelessWidget {
  const FavoriteMenu({super.key, required this.minWidth});

  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: _kHorizontalPadding,
        right: _kHorizontalPadding,
        top: _kVerticalPadding,
        bottom: _kVerticalPadding,
      ),
      child: BlocProvider(
        create: (context) =>
            FavoriteMenuBloc()..add(const FavoriteMenuEvent.initial()),
        child: BlocBuilder<FavoriteMenuBloc, FavoriteMenuState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VSpace(4),
                SpaceSearchField(
                  width: minWidth - 2 * _kHorizontalPadding,
                  onSearch: (context, text) {
                    context
                        .read<FavoriteMenuBloc>()
                        .add(FavoriteMenuEvent.search(text));
                  },
                ),
                const VSpace(12),
                _FavoriteGroups(
                  minWidth: minWidth,
                  state: state,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FavoriteGroupedViews extends StatelessWidget {
  const _FavoriteGroupedViews({
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: views
          .map(
            (e) => ViewItem(
              key: ValueKey(e.id),
              view: e,
              spaceType: FolderSpaceType.favorite,
              level: 0,
              onSelected: (_, view) {
                context.read<TabsBloc>().openPlugin(view);
                PopoverContainer.maybeOf(context)?.close();
              },
              isFeedback: false,
              isDraggable: false,
              shouldRenderChildren: false,
              extendBuilder: (view) => view.isPinned
                  ? [
                      const HSpace(4.0),
                      const FlowySvg(
                        FlowySvgs.favorite_pin_s,
                        blendMode: null,
                      ),
                    ]
                  : [],
              leftIconBuilder: (_, __) => const HSpace(4.0),
              rightIconsBuilder: (_, view) => [
                FavoriteMoreActions(view: view),
                const HSpace(6.0),
                FavoritePinAction(view: view),
                const HSpace(4.0),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _FavoriteGroups extends StatelessWidget {
  const _FavoriteGroups({
    required this.minWidth,
    required this.state,
  });

  final double minWidth;
  final FavoriteMenuState state;

  @override
  Widget build(BuildContext context) {
    final today = _buildGroups(
      context,
      state.todayViews,
      LocaleKeys.sideBar_today.tr(),
    );
    final thisWeek = _buildGroups(
      context,
      state.thisWeekViews,
      LocaleKeys.sideBar_thisWeek.tr(),
    );
    final others = _buildGroups(
      context,
      state.otherViews,
      LocaleKeys.sideBar_others.tr(),
    );

    return Container(
      width: minWidth - 2 * _kHorizontalPadding,
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (today.isNotEmpty) ...[
              ...today,
            ],
            if (thisWeek.isNotEmpty) ...[
              if (today.isNotEmpty) ...[
                const FlowyDivider(),
                const VSpace(16),
              ],
              ...thisWeek,
            ],
            if ((thisWeek.isNotEmpty || today.isNotEmpty) &&
                others.isNotEmpty) ...[
              const FlowyDivider(),
              const VSpace(16),
            ],
            ...others.isNotEmpty && (today.isNotEmpty || thisWeek.isNotEmpty)
                ? others
                : _buildGroups(
                    context,
                    state.otherViews,
                    LocaleKeys.sideBar_others.tr(),
                    showHeader: false,
                  ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroups(
    BuildContext context,
    List<ViewPB> views,
    String title, {
    bool showHeader = true,
  }) {
    return [
      if (views.isNotEmpty) ...[
        if (showHeader)
          FlowyText(
            title,
            fontSize: 12.0,
            color: Theme.of(context).hintColor,
          ),
        const VSpace(2),
        _FavoriteGroupedViews(views: views),
        const VSpace(8),
      ],
    ];
  }
}

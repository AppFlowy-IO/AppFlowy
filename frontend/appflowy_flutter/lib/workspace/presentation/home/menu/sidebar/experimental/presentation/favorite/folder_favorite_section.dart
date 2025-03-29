import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/favorite/folder_favorite_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/page/page_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/extensions/favorite_folder_view_pb_extensions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/favorite/favorite_page_item_more_action_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/widgets/page_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteSection extends StatelessWidget {
  const FavoriteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderFavoriteBloc, FolderFavoriteState>(
      builder: (context, state) {
        if (state.views.isEmpty) {
          return const SizedBox.shrink();
        }
        return _FavoriteSection(
          views: state.views.toList(),
        );
      },
    );
  }
}

class _FavoriteSection extends StatefulWidget {
  const _FavoriteSection({
    required this.views,
  });

  final List<FavoriteFolderViewPB> views;

  @override
  State<_FavoriteSection> createState() => _FavoriteSectionState();
}

class _FavoriteSectionState extends State<_FavoriteSection> {
  final isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.views.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderSpaceType.favorite)
        ..add(const FolderEvent.initial()),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return MouseRegion(
            onEnter: (_) => isHovered.value = true,
            onExit: (_) => isHovered.value = false,
            child: Column(
              children: [
                _FavoriteSectionHeader(
                  onPressed: () => context
                      .read<FolderBloc>()
                      .add(const FolderEvent.expandOrUnExpand()),
                ),
                buildReorderListView(context, state),
                if (state.isExpanded) ...[
                  // more button
                  const VSpace(2),
                  const _FavoriteMoreButton(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildReorderListView(
    BuildContext context,
    FolderState state,
  ) {
    if (!state.isExpanded) return const SizedBox.shrink();

    final favoriteBloc = context.read<FolderFavoriteBloc>();
    final pinnedViews = favoriteBloc.state.pinnedViews.toList();

    if (pinnedViews.isEmpty) return const SizedBox.shrink();
    if (pinnedViews.length == 1) {
      return buildViewItem(pinnedViews.first);
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        itemCount: pinnedViews.length,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, i) {
          final view = pinnedViews[i];
          return ReorderableDragStartListener(
            key: ValueKey(view.id),
            index: i,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: buildViewItem(view),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          favoriteBloc.add(FolderFavoriteEvent.reorder(oldIndex, newIndex));
        },
      ),
    );
  }

  Widget buildViewItem(FavoriteFolderViewPB view) {
    return PageItem(
      key: ValueKey('${FolderSpaceType.favorite.name} ${view.id}'),
      spaceType: FolderSpaceType.favorite,
      isDraggable: false,
      isFirstChild: view.id == widget.views.first.id,
      isFeedback: false,
      view: view.view,
      enableRightClickContext: true,
      leftPadding: HomeSpaceViewSizes.leftPadding,
      leftIconBuilder: (_, __) => const HSpace(HomeSpaceViewSizes.leftPadding),
      level: 0,
      isHovered: isHovered,
      rightIconsBuilder: (context, _) => [
        Listener(
          child: FavoritePageItemMoreActionButton(view: view),
          onPointerDown: (e) {
            context
                .read<FolderViewBloc>()
                .add(const FolderViewEvent.setIsEditing(true));
          },
        ),
        const HSpace(8.0),
        Listener(
          child: FavoritePinAction(view: view.view.viewPB),
          onPointerDown: (e) {
            context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true));
          },
        ),
        const HSpace(4.0),
      ],
      shouldRenderChildren: false,
      shouldLoadChildViews: false,
      onTertiarySelected: (_, view) =>
          context.read<TabsBloc>().openTab(view.viewPB),
      onSelected: (_, view) {
        if (HardwareKeyboard.instance.isControlPressed) {
          context.read<TabsBloc>().openTab(view.viewPB);
        }

        context.read<TabsBloc>().openPlugin(view.viewPB);
      },
    );
  }
}

class _FavoriteSectionHeader extends StatelessWidget {
  const _FavoriteSectionHeader({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeSizes.newPageSectionHeight,
      child: FlowyButton(
        onTap: onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
        leftIcon: const FlowySvg(
          FlowySvgs.favorite_header_icon_m,
          blendMode: null,
        ),
        leftIconSize: const Size.square(24.0),
        iconPadding: 8.0,
        text: FlowyText.regular(
          LocaleKeys.sideBar_favorites.tr(),
          lineHeight: 1.15,
        ),
      ),
    );
  }
}

class _FavoriteMoreButton extends StatelessWidget {
  const _FavoriteMoreButton();

  @override
  Widget build(BuildContext context) {
    final favoriteBloc = context.watch<FavoriteBloc>();
    final tabsBloc = context.read<TabsBloc>();
    final unpinnedViews = favoriteBloc.state.unpinnedViews;
    // only show the more button if there are unpinned views
    if (unpinnedViews.isEmpty) {
      return const SizedBox.shrink();
    }

    const minWidth = 260.0;
    return AppFlowyPopover(
      constraints: const BoxConstraints(
        minWidth: minWidth,
      ),
      popupBuilder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: favoriteBloc),
          BlocProvider.value(value: tabsBloc),
        ],
        child: const FavoriteMenu(minWidth: minWidth),
      ),
      margin: EdgeInsets.zero,
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 7.0),
        leftIcon: const FlowySvg(FlowySvgs.workspace_three_dots_s),
        text: FlowyText.regular(LocaleKeys.button_more.tr()),
      ),
    );
  }
}

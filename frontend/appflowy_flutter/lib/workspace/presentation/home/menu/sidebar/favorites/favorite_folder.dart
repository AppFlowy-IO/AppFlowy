import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_more_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteFolder extends StatefulWidget {
  const FavoriteFolder({super.key, required this.views});

  final List<ViewPB> views;

  @override
  State<FavoriteFolder> createState() => _FavoriteFolderState();
}

class _FavoriteFolderState extends State<FavoriteFolder> {
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
                FavoriteHeader(
                  onPressed: () => context
                      .read<FolderBloc>()
                      .add(const FolderEvent.expandOrUnExpand()),
                ),
                buildReorderListView(context, state),
                if (state.isExpanded) ...[
                  // more button
                  const VSpace(2),
                  const FavoriteMoreButton(),
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

    final favoriteBloc = context.read<FavoriteBloc>();
    final pinnedViews =
        favoriteBloc.state.pinnedViews.map((e) => e.item).toList();

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
          favoriteBloc.add(FavoriteEvent.reorder(oldIndex, newIndex));
        },
      ),
    );
  }

  Widget buildViewItem(ViewPB view) {
    return ViewItem(
      key: ValueKey('${FolderSpaceType.favorite.name} ${view.id}'),
      spaceType: FolderSpaceType.favorite,
      isDraggable: false,
      isFirstChild: view.id == widget.views.first.id,
      isFeedback: false,
      view: view,
      enableRightClickContext: true,
      leftPadding: HomeSpaceViewSizes.leftPadding,
      leftIconBuilder: (_, __) => const HSpace(HomeSpaceViewSizes.leftPadding),
      level: 0,
      isHovered: isHovered,
      rightIconsBuilder: (context, view) => [
        Listener(
          child: FavoriteMoreActions(view: view),
          onPointerDown: (e) {
            context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true));
          },
        ),
        const HSpace(8.0),
        Listener(
          child: FavoritePinAction(view: view),
          onPointerDown: (e) {
            context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true));
          },
        ),
        const HSpace(4.0),
      ],
      shouldRenderChildren: false,
      shouldLoadChildViews: false,
      onTertiarySelected: (_, view) => context.read<TabsBloc>().openTab(view),
      onSelected: (_, view) {
        if (HardwareKeyboard.instance.isControlPressed) {
          context.read<TabsBloc>().openTab(view);
        }

        context.read<TabsBloc>().openPlugin(view);
      },
    );
  }
}

class FavoriteHeader extends StatelessWidget {
  const FavoriteHeader({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFGhostIconTextButton.primary(
      text: LocaleKeys.sideBar_favorites.tr(),
      mainAxisAlignment: MainAxisAlignment.start,
      size: AFButtonSize.l,
      onTap: () {},
      // todo: ask the designer to provide the token.
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      borderRadius: theme.borderRadius.s,
      iconBuilder: (context, isHover, disabled) => const FlowySvg(
        FlowySvgs.favorite_header_icon_m,
        blendMode: null,
        size: Size.square(22.0),
      ),
    );
  }
}

class FavoriteMoreButton extends StatelessWidget {
  const FavoriteMoreButton({super.key});

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

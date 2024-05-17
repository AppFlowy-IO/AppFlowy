import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_more_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteFolder extends StatefulWidget {
  const FavoriteFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  State<FavoriteFolder> createState() => _FavoriteFolderState();
}

class _FavoriteFolderState extends State<FavoriteFolder> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);

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
                // pages
                ..._buildViews(context, state),
                // more button
                const FavoriteMoreButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Iterable<Widget> _buildViews(BuildContext context, FolderState state) {
    if (!state.isExpanded) {
      return [];
    }

    return context.read<FavoriteBloc>().state.pinnedViews.map(
          (view) => ViewItem(
            key: ValueKey(
              '${FolderSpaceType.favorite.name} ${view.id}',
            ),
            spaceType: FolderSpaceType.favorite,
            isDraggable: false,
            isFirstChild: view.id == widget.views.first.id,
            isFeedback: false,
            view: view,
            height: 30.0,
            leftPadding: 16.0,
            level: 0,
            isHovered: isHovered,
            rightIconsBuilder: (context, view) => [
              FavoriteMoreActions(view: view),
              const HSpace(8.0),
              FavoritePinAction(view: view),
              const HSpace(4.0),
            ],
            onTertiarySelected: (_, view) =>
                context.read<TabsBloc>().openTab(view),
            onSelected: (_, view) {
              if (HardwareKeyboard.instance.isControlPressed) {
                context.read<TabsBloc>().openTab(view);
              }

              context.read<TabsBloc>().openPlugin(view);
            },
          ),
        );
  }
}

class FavoriteHeader extends StatelessWidget {
  const FavoriteHeader({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: onPressed,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 7.0),
      leftIcon: const FlowySvg(
        FlowySvgs.favorite_header_icon_s,
        blendMode: null,
      ),
      iconPadding: 10.0,
      text: FlowyText.regular(LocaleKeys.sideBar_favorites.tr()),
    );
  }
}

class FavoriteMoreButton extends StatelessWidget {
  const FavoriteMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteBloc = context.watch<FavoriteBloc>();
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
      decoration: FlowyDecoration.decoration(
        Theme.of(context).cardColor,
        Theme.of(context).colorScheme.shadow,
        borderRadius: 10.0,
      ),
      popupBuilder: (_) {
        return BlocProvider.value(
          value: favoriteBloc,
          child: const FavoriteMenu(minWidth: minWidth),
        );
      },
      child: FlowyButton(
        onTap: () {},
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
        leftIcon: const FlowySvg(
          FlowySvgs.workspace_three_dots_s,
          blendMode: null,
        ),
        text: FlowyText.regular(LocaleKeys.button_more.tr()),
      ),
    );
  }
}

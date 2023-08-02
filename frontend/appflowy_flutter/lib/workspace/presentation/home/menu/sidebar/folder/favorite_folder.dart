import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
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
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final views = widget.views;
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        FavoriteHeader(
          onPressed: () => setState(
            () => isExpanded = !isExpanded,
          ),
          onAdded: () => setState(() => isExpanded = true),
        ),
        if (isExpanded)
          ...views.map(
            (view) => ViewItem(
              key: ValueKey(
                '${SidebarFolderCategoryType.favorite.name} ${view.id}',
              ),
              categoryType: SidebarFolderCategoryType.favorite,
              isDraggable: false,
              isFirstChild: view.id == views.first.id,
              view: view,
              level: 0,
              onSelected: (view) {
                getIt<MenuSharedState>().latestOpenView = view;
                context.read<MenuBloc>().add(MenuEvent.openPage(view.plugin()));
              },
            ),
          )
      ],
    );
  }
}

class FavoriteHeader extends StatefulWidget {
  const FavoriteHeader({
    super.key,
    required this.onPressed,
    required this.onAdded,
  });

  final VoidCallback onPressed;
  final VoidCallback onAdded;

  @override
  State<FavoriteHeader> createState() => _FavoriteHeaderState();
}

class _FavoriteHeaderState extends State<FavoriteHeader> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    const iconSize = 26.0;
    return MouseRegion(
      onEnter: (event) => setState(() => onHover = true),
      onExit: (event) => setState(() => onHover = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FlowyTextButton(
            LocaleKeys.sideBar_favorites.tr(),
            tooltip: LocaleKeys.sideBar_clickToHideFavorites.tr(),
            constraints: const BoxConstraints(maxHeight: iconSize),
            padding: const EdgeInsets.all(4),
            fillColor: Colors.transparent,
            onPressed: widget.onPressed,
          ),
        ],
      ),
    );
  }
}

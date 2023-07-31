import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarFavorite extends StatefulWidget {
  const SidebarFavorite({super.key});

  @override
  State<SidebarFavorite> createState() => _SidebarFavoriteState();
}

class _SidebarFavoriteState extends State<SidebarFavorite> {
  bool isExpanded = true;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        if (state.objects.isNotEmpty) {
          return Column(
            children: [
              FavoriteHeader(
                onPressed: () => setState(
                  () => isExpanded = !isExpanded,
                ),
                onAdded: () => setState(() => isExpanded = true),
              ),
              if (isExpanded)
                ...state.objects.map(
                  (view) => ViewItem(
                    key: ValueKey(view.id),
                    isFirstChild: view.id == state.objects.first.id,
                    view: view,
                    level: 0,
                    onSelected: (view) {
                      getIt<MenuSharedState>().latestOpenView = view;
                      context
                          .read<MenuBloc>()
                          .add(MenuEvent.openPage(view.plugin()));
                    },
                  ),
                )
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
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
            tooltip: LocaleKeys.sideBar_favorites.tr(),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteFolder extends StatelessWidget {
  const FavoriteFolder({
    super.key,
    required this.views,
  });

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }

    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderCategoryType.favorite)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              FavoriteHeader(
                onPressed: () => context
                    .read<FolderBloc>()
                    .add(const FolderEvent.expandOrUnExpand()),
                onAdded: () => context
                    .read<FolderBloc>()
                    .add(const FolderEvent.expandOrUnExpand(isExpanded: true)),
              ),
              if (state.isExpanded)
                ...views.map(
                  (view) => ViewItem(
                    key: ValueKey(
                      '${FolderCategoryType.favorite.name} ${view.id}',
                    ),
                    categoryType: FolderCategoryType.favorite,
                    isDraggable: false,
                    isFirstChild: view.id == views.first.id,
                    isFeedback: false,
                    view: view,
                    level: 0,
                    onSelected: (view, _) {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        context.read<TabsBloc>().openTab(view);
                      }

                      context.read<TabsBloc>().openPlugin(view);
                    },
                    onTertiarySelected: (view, _) =>
                        context.read<TabsBloc>().openTab(view),
                  ),
                ),
            ],
          );
        },
      ),
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
        children: [
          FlowyTextButton(
            LocaleKeys.sideBar_favorites.tr(),
            fontColor: AFThemeExtension.of(context).textColor,
            fontHoverColor: Theme.of(context).colorScheme.onSurface,
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

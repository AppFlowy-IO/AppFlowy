import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

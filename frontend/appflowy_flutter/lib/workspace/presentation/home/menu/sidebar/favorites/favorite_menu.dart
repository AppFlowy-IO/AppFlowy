import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_more_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FavoriteSearchField(
              width: minWidth - 2 * _kHorizontalPadding,
              onSearch: (context, text) {
                context
                    .read<FavoriteMenuBloc>()
                    .add(FavoriteMenuEvent.search(text));
              },
            ),
            const VSpace(12),
            _buildViews(context),
          ],
        ),
      ),
    );
  }

  Widget _buildViews(BuildContext context) {
    return BlocBuilder<FavoriteMenuBloc, FavoriteMenuState>(
      builder: (context, state) {
        return Container(
          width: minWidth - 2 * _kHorizontalPadding,
          constraints: const BoxConstraints(
            maxHeight: 300,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.queriedViews
                  .map(
                    (e) => ViewItem(
                      key: ValueKey(e.id),
                      view: e,
                      spaceType: FolderSpaceType.favorite,
                      level: 0,
                      onSelected: (view, _) {},
                      isFeedback: false,
                      isDraggable: false,
                      shouldRenderChildren: false,
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
            ),
          ),
        );
      },
    );
  }
}

class _FavoriteSearchField extends StatelessWidget {
  const _FavoriteSearchField({
    required this.width,
    required this.onSearch,
  });

  final double width;
  final void Function(BuildContext context, String text) onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1.20,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0xFF00BCF0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: CupertinoSearchTextField(
        onChanged: (text) => onSearch(context, text),
        padding: EdgeInsets.zero,
        placeholder: LocaleKeys.search_label.tr(),
        prefixIcon: const FlowySvg(FlowySvgs.m_search_m),
        prefixInsets: const EdgeInsets.only(left: 12.0, right: 8.0),
        suffixIcon: const Icon(Icons.close),
        suffixInsets: const EdgeInsets.only(right: 8.0),
        itemSize: 16.0,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w400,
            ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
            ),
      ),
    );
  }
}

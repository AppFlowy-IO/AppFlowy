import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_menu_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_more_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/favorites/favorite_pin_action.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
        child: BlocBuilder<FavoriteMenuBloc, FavoriteMenuState>(
          builder: (context, state) {
            if (state.views.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VSpace(4),
                _FavoriteSearchField(
                  width: minWidth - 2 * _kHorizontalPadding,
                  onSearch: (context, text) {
                    context
                        .read<FavoriteMenuBloc>()
                        .add(FavoriteMenuEvent.search(text));
                  },
                ),
                const VSpace(12),
                _buildViews(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildViews(BuildContext context, FavoriteMenuState state) {
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
              const VSpace(8),
              const Divider(height: 1),
              const VSpace(8),
            ],
            if (thisWeek.isNotEmpty) ...[
              ...thisWeek,
              const VSpace(8),
              const Divider(height: 1),
              const VSpace(8),
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
          SizedBox(
            height: 24,
            child: FlowyText(
              title,
              fontSize: 12.0,
              color: Theme.of(context).hintColor,
            ),
          ),
        const VSpace(2),
        _buildGroupedViews(context, views),
        const VSpace(8),
      ],
    ];
  }

  Widget _buildGroupedViews(BuildContext context, List<ViewPB> views) {
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

class _FavoriteSearchField extends StatefulWidget {
  const _FavoriteSearchField({
    required this.width,
    required this.onSearch,
  });

  final double width;
  final void Function(BuildContext context, String text) onSearch;

  @override
  State<_FavoriteSearchField> createState() => _FavoriteSearchFieldState();
}

class _FavoriteSearchFieldState extends State<_FavoriteSearchField> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: widget.width,
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
        onChanged: (text) => widget.onSearch(context, text),
        padding: EdgeInsets.zero,
        focusNode: focusNode,
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

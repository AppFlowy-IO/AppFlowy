import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/search/mobile_view_ancestors.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'page_preview.dart';
import 'search_highlight.dart';

class SearchResultCell extends StatefulWidget {
  const SearchResultCell({
    super.key,
    required this.item,
    required this.isNarrowWindow,
    this.view,
    this.query,
    this.isHovered = false,
  });

  final SearchResultItem item;
  final ViewPB? view;
  final String? query;
  final bool isHovered;
  final bool isNarrowWindow;

  @override
  State<SearchResultCell> createState() => _SearchResultCellState();
}

class _SearchResultCellState extends State<SearchResultCell> {
  bool _hasFocus = false;
  final focusNode = FocusNode();

  String get viewId => item.id;
  SearchResultItem get item => widget.item;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  /// Helper to handle the selection action.
  void _handleSelection() {
    context.read<SearchResultListBloc>().add(
          SearchResultListEvent.openPage(pageId: viewId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = item.displayName.orDefault(
      LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
    );
    final searchResultBloc = context.read<SearchResultListBloc>();
    final hasHovered = searchResultBloc.state.hoveredResult != null;

    final theme = AppFlowyTheme.of(context);
    final titleStyle = theme.textStyle.body
        .enhanced(color: theme.textColorScheme.primary)
        .copyWith(height: 22 / 14);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSelection,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleSelection();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (hasFocus) {
          setState(() {
            searchResultBloc.add(
              SearchResultListEvent.onHoverResult(
                item: item,
                userHovered: true,
              ),
            );
            _hasFocus = hasFocus;
          });
        },
        child: FlowyHover(
          onHover: (value) {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.onHoverResult(
                    item: item,
                    userHovered: true,
                  ),
                );
          },
          isSelected: () => _hasFocus || widget.isHovered,
          style: HoverStyle(
            borderRadius: BorderRadius.circular(8),
            hoverColor: theme.fillColorScheme.contentHover,
            foregroundColorOnHover: AFThemeExtension.of(context).textColor,
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: Center(child: buildIcon(theme)),
                    ),
                    HSpace(8),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: (!widget.isNarrowWindow && hasHovered)
                            ? 480.0
                            : 680.0,
                      ),
                      child: RichText(
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        text: buildSearchHighlightSpan(
                          content: title,
                          query: widget.query,
                          normal: titleStyle,
                          highlight: titleStyle.copyWith(
                            backgroundColor: theme.fillColorScheme.themeSelect,
                          ),
                        ),
                      ),
                    ),
                    Flexible(child: buildPath(theme)),
                  ],
                ),
                ...buildSummary(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildIcon(AppFlowyThemeData theme) {
    final view = widget.view;
    if (view != null) return view.buildIcon(context);
    return item.icon.buildIcon(context) ?? const SizedBox.shrink();
  }

  Widget buildPath(AppFlowyThemeData theme) {
    return BlocProvider(
      key: ValueKey(item.id),
      create: (context) => ViewAncestorBloc(item.id),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) {
          if (state.ancestor.ancestors.isEmpty) return const SizedBox.shrink();
          return state.buildOnelinePath(context);
        },
      ),
    );
  }

  List<Widget> buildSummary(AppFlowyThemeData theme) {
    if (item.content.isEmpty) return [];
    final style = theme.textStyle.caption
        .standard(color: theme.textColorScheme.secondary)
        .copyWith(letterSpacing: 0.1);
    return [
      VSpace(4),
      Padding(
        padding: const EdgeInsets.only(left: 28),
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: buildSearchHighlightSpan(
            content: item.content,
            query: widget.query,
            normal: style,
            highlight: style.copyWith(
              backgroundColor: theme.fillColorScheme.themeSelect,
              color: theme.textColorScheme.primary,
            ),
          ),
        ),
      ),
    ];
  }
}

class SearchResultPreview extends StatelessWidget {
  const SearchResultPreview({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return PagePreview(
      view: view,
      key: ValueKey(view.id),
      onViewOpened: () {
        context
            .read<SearchResultListBloc?>()
            ?.add(SearchResultListEvent.openPage(pageId: view.id));
      },
    );
  }
}

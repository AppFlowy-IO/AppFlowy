import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_cell.dart';
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

import 'keyboard_scroller.dart';
import 'page_preview.dart';

class SearchResultCell extends StatefulWidget {
  const SearchResultCell({
    super.key,
    required this.bloc,
    required this.detectors,
    required this.item,
    required this.isNarrowWindow,
    this.view,
    this.query,
    this.isHovered = false,
  });

  final SearchResultItem item;
  final SearchResultListBloc bloc;
  final AreaDetectors detectors;
  final ViewPB? view;
  final String? query;
  final bool isHovered;
  final bool isNarrowWindow;

  @override
  State<SearchResultCell> createState() => _SearchResultCellState();
}

class _SearchResultCellState extends State<SearchResultCell> {
  final focusNode = FocusNode();
  final itemKey = GlobalKey();

  String get viewId => item.id;
  SearchResultItem get item => widget.item;
  SearchResultListBloc get bloc => widget.bloc;

  AreaDetectors get detectors => widget.detectors;

  @override
  void initState() {
    super.initState();
    detectors.addDetector(viewId, getAreaType);
  }

  @override
  void dispose() {
    focusNode.dispose();
    detectors.removeDetector(viewId, getAreaType);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = item.displayName.orDefault(
      LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
    );
    final hasHovered = bloc.state.hoveredResult != null;

    final theme = AppFlowyTheme.of(context);
    final titleStyle = theme.textStyle.body
        .enhanced(color: theme.textColorScheme.primary)
        .copyWith(height: 22 / 14);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleSelection,
      key: itemKey,
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
        child: FlowyHover(
          onHover: (value) {
            bloc.add(
              SearchResultListEvent.onHoverResult(
                item: item,
                userHovered: true,
              ),
            );
          },
          isSelected: () => widget.isHovered,
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
                        text: buildHighLightSpan(
                          content: title,
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

  TextSpan buildHighLightSpan({
    required String content,
    required TextStyle normal,
    required TextStyle highlight,
  }) {
    final queryText = (widget.query ?? '').trim();
    if (queryText.isEmpty) {
      return TextSpan(text: content, style: normal);
    }
    final contents = content.splitIncludeSeparator(queryText);
    return TextSpan(
      children: List.generate(contents.length, (index) {
        final content = contents[index];
        final isHighlight = content.toLowerCase() == queryText.toLowerCase();
        return TextSpan(
          text: content,
          style: isHighlight ? highlight : normal,
        );
      }),
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
          text: buildHighLightSpan(
            content: item.content,
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

  /// Helper to handle the selection action.
  void _handleSelection() =>
      bloc.add(SearchResultListEvent.openPage(pageId: viewId));

  AreaType? getAreaType() => itemKey.getAreaTypeInSearchPanel(context);
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

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_cell.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchSummaryCell extends StatefulWidget {
  const SearchSummaryCell({
    required this.summary,
    required this.maxWidth,
    required this.theme,
    required this.textStyle,
    super.key,
  });

  final SearchSummaryPB summary;
  final double maxWidth;
  final AppFlowyThemeData theme;
  final TextStyle textStyle;

  @override
  State<SearchSummaryCell> createState() => _SearchSummaryCellState();
}

class _SearchSummaryCellState extends State<SearchSummaryCell> {
  late TextPainter _painter;
  late _TextInfo _textInfo = _TextInfo.normal(summary.content);
  bool tappedShowMore = false;
  final maxLines = 5;
  final popoverController = PopoverController();
  bool isLinkHovering = false, isReferenceHovering = false;

  SearchSummaryPB get summary => widget.summary;
  double get maxWidth => widget.maxWidth;
  AppFlowyThemeData get theme => widget.theme;

  TextStyle get textStyle => widget.textStyle;

  TextStyle get showMoreStyle => theme.textStyle.body.standard(
        color: theme.textColorScheme.secondary,
      );

  TextStyle get showMoreUnderlineStyle => theme.textStyle.body.underline(
        color: theme.textColorScheme.secondary,
      );

  @override
  void initState() {
    super.initState();
    refreshTextPainter();
  }

  @override
  void didUpdateWidget(SearchSummaryCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxWidth != maxWidth) {
      refreshTextPainter();
    }
  }

  @override
  void dispose() {
    _painter.dispose();
    popoverController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showReference = summary.sources.isNotEmpty;
    final query = summary.highlights.isEmpty
        ? context.read<CommandPaletteBloc?>()?.state.query
        : summary.highlights;

    return _textInfo.build(
      context: context,
      normal: textStyle,
      more: showMoreStyle,
      query: query ?? '',
      moreUnderline: showMoreUnderlineStyle,
      showMore: () {
        setState(() {
          tappedShowMore = true;
          _textInfo = _TextInfo.normal(summary.content);
        });
      },
      normalWidgetSpan: showReference
          ? WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (event) {
                    if (!isLinkHovering) {
                      isLinkHovering = true;
                      showPopover();
                    }
                  },
                  onExit: (event) {
                    if (isLinkHovering) {
                      isLinkHovering = false;
                      tryToHidePopover();
                    }
                  },
                  child: buildReferenceIcon(),
                ),
              ),
            )
          : null,
    );
  }

  Widget buildReferenceIcon() {
    final iconSize = Size(21, 15), placeholderHeight = iconSize.height + 10.0;
    return AppFlowyPopover(
      offset: Offset(0, -iconSize.height),
      constraints:
          BoxConstraints(maxWidth: 360, maxHeight: 420 + placeholderHeight),
      direction: PopoverDirection.bottomWithCenterAligned,
      margin: EdgeInsets.zero,
      controller: popoverController,
      decorationColor: Colors.transparent,
      popoverDecoration: BoxDecoration(),
      popupBuilder: (popoverContext) => MouseRegion(
        onEnter: (event) {
          if (!isReferenceHovering) {
            isReferenceHovering = true;
          }
        },
        onExit: (event) {
          if (isReferenceHovering) {
            isReferenceHovering = false;
            tryToHidePopover();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: placeholderHeight),
            Flexible(
              child: ReferenceSources(
                summary.sources,
                onClose: () {
                  hidePopover();
                  if (context.mounted) FlowyOverlay.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
      child: Container(
        width: iconSize.width,
        height: iconSize.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FlowySvg(
          FlowySvgs.toolbar_link_m,
          color: theme.iconColorScheme.primary,
          size: Size.square(10),
        ),
      ),
    );
  }

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  void hidePopover() {
    popoverController.close();
    keepEditorFocusNotifier.decrease();
  }

  void tryToHidePopover() {
    if (isLinkHovering || isReferenceHovering) return;
    Future.delayed(Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      if (isLinkHovering || isReferenceHovering) return;
      hidePopover();
    });
  }

  void refreshTextPainter() {
    final content = summary.content,
        ellipsis = ' ...${LocaleKeys.search_seeMore.tr()}';
    if (!tappedShowMore) {
      _painter = TextPainter(
        text: TextSpan(text: content, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: ellipsis,
      );
      _painter.layout(maxWidth: maxWidth);
      if (_painter.didExceedMaxLines) {
        final lines = _painter.computeLineMetrics();
        final lastLine = lines.last;
        final offset = Offset(
          lastLine.left + lastLine.width,
          lines.map((e) => e.height).reduce((a, b) => a + b),
        );
        final range = _painter.getPositionForOffset(offset);
        final text = content.substring(0, range.offset);
        _textInfo = _TextInfo.overflow(text);
      } else {
        _textInfo = _TextInfo.normal(content);
      }
    }
  }
}

class _TextInfo {
  _TextInfo({required this.text, required this.isOverflow});

  _TextInfo.normal(this.text) : isOverflow = false;

  _TextInfo.overflow(this.text) : isOverflow = true;

  final String text;
  final bool isOverflow;

  Widget build({
    required BuildContext context,
    required TextStyle normal,
    required TextStyle more,
    required TextStyle moreUnderline,
    required VoidCallback showMore,
    required String query,
    WidgetSpan? normalWidgetSpan,
  }) {
    final theme = AppFlowyTheme.of(context);
    if (isOverflow) {
      return SelectionArea(
        child: Text.rich(
          TextSpan(
            children: [
              _buildHighLightSpan(
                content: text,
                normal: normal,
                query: query,
                highlight: normal.copyWith(
                  backgroundColor: theme.fillColorScheme.themeSelect,
                ),
              ),
              TextSpan(
                text: ' ...',
                style: normal,
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AFBaseButton(
                  padding: EdgeInsets.zero,
                  builder: (context, isHovering, disabled) =>
                      SelectionContainer.disabled(
                    child: Text(
                      LocaleKeys.search_seeMore.tr(),
                      style: isHovering ? moreUnderline : more,
                    ),
                  ),
                  borderColor: (_, __, ___, ____) => Colors.transparent,
                  borderRadius: 0,
                  onTap: showMore,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SelectionArea(
        child: Text.rich(
          TextSpan(
            children: [
              _buildHighLightSpan(
                content: text,
                normal: normal,
                query: query,
                highlight: normal.copyWith(
                  backgroundColor: theme.fillColorScheme.themeSelect,
                ),
              ),
              if (normalWidgetSpan != null) normalWidgetSpan,
            ],
          ),
        ),
      );
    }
  }

  TextSpan _buildHighLightSpan({
    required String content,
    required TextStyle normal,
    required TextStyle highlight,
    String? query,
  }) {
    final queryText = (query ?? '').trim();
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
}

class ReferenceSources extends StatelessWidget {
  const ReferenceSources(
    this.sources, {
    super.key,
    this.onClose,
  });

  final List<SearchSourcePB> sources;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final bloc = context.read<CommandPaletteBloc?>(), state = bloc?.state;

    return Container(
      decoration: ShapeDecoration(
        color: theme.surfaceColorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.spacing.m),
        ),
        shadows: theme.shadow.small,
      ),
      padding: EdgeInsets.all(8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Text(
                LocaleKeys.commandPalette_aiOverviewSource.tr(),
                style: theme.textStyle.body.enhanced(
                  color: theme.textColorScheme.secondary,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final source = sources[index];
                final view = state?.cachedViews[source.id];

                final displayName = source.displayName.isEmpty
                    ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                    : source.displayName;
                final spaceM = theme.spacing.m, spaceL = theme.spacing.l;

                return AFBaseButton(
                  borderRadius: spaceM,
                  onTap: () {
                    getIt<ActionNavigationBloc>().add(
                      ActionNavigationEvent.performAction(
                        action: NavigationAction(objectId: source.id),
                      ),
                    );
                    onClose?.call();
                  },
                  padding: EdgeInsets.symmetric(
                    vertical: spaceL,
                    horizontal: spaceM,
                  ),
                  backgroundColor: (context, isHovering, disable) {
                    if (isHovering) {
                      return theme.fillColorScheme.contentHover;
                    }
                    return Colors.transparent;
                  },
                  borderColor: (context, isHovering, disabled, isFocused) =>
                      Colors.transparent,
                  builder: (context, isHovering, disabled) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: Center(
                          child: view?.buildIcon(context) ??
                              source.icon.buildIcon(context),
                        ),
                      ),
                      HSpace(8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textStyle.body.standard(
                                color: theme.textColorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => AFDivider(),
              itemCount: sources.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIcon(ResultIconPB icon, AppFlowyThemeData theme) {
    if (icon.ty == ResultIconTypePB.Emoji) {
      return icon.getIcon(size: 16, lineHeight: 21 / 16) ?? SizedBox.shrink();
    } else {
      return icon.getIcon(iconColor: theme.iconColorScheme.primary) ??
          SizedBox.shrink();
    }
  }
}

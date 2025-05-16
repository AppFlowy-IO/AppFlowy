import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/tab/mobile_space_tab.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_cell.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mobile_search_reference_bottom_sheet.dart';

class MobileSearchSummaryCell extends StatefulWidget {
  const MobileSearchSummaryCell({
    super.key,
    required this.summary,
    required this.maxWidth,
    required this.theme,
  });

  final SearchSummaryPB summary;
  final double maxWidth;
  final AppFlowyThemeData theme;

  @override
  State<MobileSearchSummaryCell> createState() =>
      _MobileSearchSummaryCellState();
}

class _MobileSearchSummaryCellState extends State<MobileSearchSummaryCell> {
  late TextPainter _painter;
  late _TextInfo _textInfo = _TextInfo.normal(summary.content);
  bool tappedShowMore = false;
  final maxLines = 4;

  SearchSummaryPB get summary => widget.summary;
  double get maxWidth => widget.maxWidth;
  AppFlowyThemeData get theme => widget.theme;

  TextStyle get textStyle =>
      theme.textStyle.heading4.standard(color: theme.textColorScheme.primary);

  TextStyle get showMoreStyle =>
      theme.textStyle.heading4.standard(color: theme.textColorScheme.secondary);

  @override
  void initState() {
    super.initState();
    refreshTextPainter();
  }

  @override
  void didUpdateWidget(MobileSearchSummaryCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxWidth != maxWidth) {
      refreshTextPainter();
    }
  }

  @override
  void dispose() {
    _painter.dispose();
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
      summury: summary,
      query: query ?? '',
      showMore: () {
        setState(() {
          tappedShowMore = true;
          _textInfo = _TextInfo.normal(summary.content);
        });
      },
      normalWidgetSpan: showReference
          ? WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showPageReferences(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 21,
                    height: 15,
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
                ),
              ),
            )
          : null,
      overflowFadeCover: buildFadeCover(),
    );
  }

  Widget buildFadeCover() {
    final fillColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      width: maxWidth,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            fillColor.withValues(alpha: 0),
            fillColor.withValues(alpha: 0.6 * 255),
            fillColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  void refreshTextPainter() {
    final content = summary.content;
    if (!tappedShowMore) {
      _painter = TextPainter(
        text: TextSpan(text: content, style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
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

  void showPageReferences(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    showMobileBottomSheet(
      AppGlobals.rootNavKey.currentContext ?? context,
      showDragHandle: true,
      showDivider: false,
      enableDraggableScrollable: true,
      backgroundColor: theme.surfaceColorScheme.primary,
      builder: (_) => SearchSourceReferenceBottomSheet(summary.sources),
    );
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
    required VoidCallback showMore,
    required String query,
    required SearchSummaryPB summury,
    WidgetSpan? normalWidgetSpan,
    Widget? overflowFadeCover,
  }) {
    final theme = AppFlowyTheme.of(context);
    if (isOverflow) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: showMore,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SelectionArea(
                  child: Text.rich(
                    _buildHighLightSpan(
                      content: text,
                      normal: normal,
                      query: query,
                      highlight: normal.copyWith(
                        backgroundColor: theme.fillColorScheme.themeSelect,
                      ),
                    ),
                  ),
                ),
                if (overflowFadeCover != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: overflowFadeCover,
                  ),
              ],
            ),
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: FlowySvg(
                      FlowySvgs.arrow_down_s,
                      size: Size.square(20),
                      color: theme.iconColorScheme.secondary,
                    ),
                  ),
                  HSpace(8),
                  Text(LocaleKeys.search_showMore.tr(), style: more),
                ],
              ),
            ),
            VSpace(16),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectionArea(
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
          ),
          VSpace(12),
          SizedBox(
            width: 156,
            height: 42,
            child: AFOutlinedButton.normal(
              borderRadius: 21,
              padding: EdgeInsets.zero,
              builder: (context, hovering, disabled) {
                return Center(
                  child: SizedBox(
                    height: 22,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlowySvg(
                          FlowySvgs.chat_ai_page_s,
                          size: Size.square(20),
                          color: theme.iconColorScheme.secondary,
                        ),
                        HSpace(8),
                        Text(
                          LocaleKeys.commandPalette_aiAskFollowUp.tr(),
                          style: theme.textStyle.heading4.standard(
                            color: theme.textColorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onTap: () {
                context.read<CommandPaletteBloc?>()?.add(
                      CommandPaletteEvent.goingToAskAI(
                        sources: summury.sources,
                      ),
                    );
                mobileCreateNewAIChatNotifier.value =
                    mobileCreateNewAIChatNotifier.value + 1;
              },
            ),
          ),
          VSpace(16),
        ],
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

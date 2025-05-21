import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_special_styles.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_summary_cell.dart';

class SearchAskAiEntrance extends StatelessWidget {
  const SearchAskAiEntrance({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CommandPaletteBloc?>(), state = bloc?.state;
    if (bloc == null || state == null) return _AskAIFor();

    final generatingAIOverview = state.generatingAIOverview;
    if (generatingAIOverview) return _AISearching();

    final hasMockSummary = _mockSummary?.isNotEmpty ?? false,
        hasSummaries = state.resultSummaries.isNotEmpty;
    if (hasMockSummary || hasSummaries) return _AIOverview();

    return _AskAIFor();
  }
}

class _AskAIFor extends StatelessWidget {
  const _AskAIFor();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final spaceM = theme.spacing.m, spaceXL = theme.spacing.xl;
    return Padding(
      padding: EdgeInsets.only(top: spaceM),
      child: AFBaseButton(
        borderRadius: spaceM,
        padding: EdgeInsets.symmetric(vertical: spaceXL, horizontal: spaceM),
        backgroundColor: (context, isHovering, disable) {
          if (isHovering) {
            return theme.fillColorScheme.contentHover;
          }
          return Colors.transparent;
        },
        borderColor: (context, isHovering, disable, isFocused) =>
            Colors.transparent,
        builder: (ctx, isHovering, disable) {
          return Row(
            children: [
              SizedBox.square(
                dimension: 24,
                child: Center(
                  child: FlowySvg(
                    FlowySvgs.m_home_ai_chat_icon_m,
                    size: Size.square(20),
                    blendMode: null,
                  ),
                ),
              ),
              HSpace(8),
              buildText(context),
            ],
          );
        },
        onTap: () {
          context
              .read<CommandPaletteBloc?>()
              ?.add(CommandPaletteEvent.goingToAskAI());
        },
      ),
    );
  }

  Widget buildText(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final bloc = context.read<CommandPaletteBloc?>();
    final queryText = bloc?.state.query ?? '';
    if (queryText.isEmpty) {
      return Text(
        LocaleKeys.search_askAIAnything.tr(),
        style:
            theme.textStyle.body.standard(color: theme.textColorScheme.primary),
      );
    }
    return Flexible(
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.search_askAIFor.tr(),
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.primary),
            ),
            TextSpan(
              text: ' "$queryText"',
              style: theme.textStyle.body
                  .enhanced(color: theme.textColorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AISearching extends StatelessWidget {
  const _AISearching();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.ai_searching_icon_m,
              size: Size.square(20),
              blendMode: null,
            ),
            HSpace(8),
            Text(
              LocaleKeys.search_searching.tr(),
              style: theme.textStyle.heading4
                  .enhanced(color: theme.textColorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIOverview extends StatelessWidget {
  const _AIOverview();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CommandPaletteBloc?>(), state = bloc?.state;
    final theme = AppFlowyTheme.of(context);
    final summaries = _mockSummary ?? state?.resultSummaries ?? [];
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.xxl,
        horizontal: theme.spacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context),
          VSpace(12),
          LayoutBuilder(
            builder: (context, constrains) {
              final summary = summaries.first;
              return SearchSummaryCell(
                key: ValueKey(summary.content.trim()),
                summary: summary,
                maxWidth: constrains.maxWidth,
                theme: AppFlowyTheme.of(context),
                textStyle: context.searchPanelTitle3,
              );
            },
          ),
          VSpace(12),
          SizedBox(
            width: 143,
            child: AFOutlinedButton.normal(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: 16,
              builder: (context, hovering, disabled) {
                return Row(
                  children: [
                    FlowySvg(
                      FlowySvgs.chat_ai_page_s,
                      size: Size.square(20),
                      color: theme.iconColorScheme.primary,
                    ),
                    HSpace(6),
                    Text(
                      LocaleKeys.commandPalette_aiAskFollowUp.tr(),
                      style: theme.textStyle.body.enhanced(
                        color: theme.textColorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
              onTap: () {
                context.read<CommandPaletteBloc?>()?.add(
                      CommandPaletteEvent.goingToAskAI(
                        sources: summaries.first.sources,
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          FlowySvg(
            FlowySvgs.ai_searching_icon_m,
            size: Size.square(20),
            blendMode: null,
          ),
          HSpace(8),
          Text(
            LocaleKeys.commandPalette_aiOverview.tr(),
            style: context.searchPanelAIOverview,
          ),
        ],
      ),
    );
  }
}

List<SearchSummaryPB>? _mockSummary;

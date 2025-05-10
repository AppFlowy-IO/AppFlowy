import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
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
    final generatingAIOverview = state?.generatingAIOverview ?? false;
    final hasAIOverview =
        _mockSummary?.isNotEmpty ?? state?.resultSummaries.isNotEmpty ?? false;
    if (generatingAIOverview) {
      return _AISearching();
    } else if (hasAIOverview) {
      return _AIOverview();
    }
    return _AskAIFor();
  }
}

class _AskAIFor extends StatelessWidget {
  const _AskAIFor();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final sapceM = theme.spacing.m, spaceL = theme.spacing.l;
    return Padding(
      padding: EdgeInsets.fromLTRB(spaceL, sapceM, spaceL, 0),
      child: AFBaseButton(
        borderRadius: sapceM,
        padding: EdgeInsets.symmetric(vertical: spaceL, horizontal: sapceM),
        backgroundColor: (context, isHovering, disable) {
          if (isHovering) {
            return Theme.of(context).colorScheme.secondary;
          }
          return theme.fillColorScheme.transparent;
        },
        borderColor: (context, isHovering, disable, isFocused) =>
            theme.fillColorScheme.transparent,
        builder: (ctx, isHovering, disable) {
          return Row(
            children: [
              FlowySvg(
                FlowySvgs.m_home_ai_chat_icon_m,
                size: Size.square(20),
                blendMode: null,
              ),
              HSpace(12),
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
      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: SizedBox(
        height: 22,
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
      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context),
          VSpace(8),
          LayoutBuilder(
            builder: (context, constrains) {
              final summary = summaries.first;
              return SearchSummaryCell(
                key: ValueKey(summary.content.trim()),
                summary: summary,
                maxWidth: constrains.maxWidth,
                theme: AppFlowyTheme.of(context),
              );
            },
          ),
          VSpace(8),
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
                    HSpace(8),
                    Text(
                      LocaleKeys.commandPalette_aiAskFollowUp.tr(),
                      style: theme.textStyle.body.standard(
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
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      height: 22,
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
            style: theme.textStyle.heading4
                .enhanced(color: theme.textColorScheme.primary),
          ),
        ],
      ),
    );
  }
}

List<SearchSummaryPB>? _mockSummary;

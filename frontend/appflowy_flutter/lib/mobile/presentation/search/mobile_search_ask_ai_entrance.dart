import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/mobile_space_tab.dart';
import 'package:appflowy/mobile/presentation/search/mobile_search_special_styles.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mobile_search_summary_cell.dart';

class MobileSearchAskAiEntrance extends StatelessWidget {
  const MobileSearchAskAiEntrance({super.key});

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
    return GestureDetector(
      onTap: () {
        context
            .read<CommandPaletteBloc?>()
            ?.add(CommandPaletteEvent.goingToAskAI());
        mobileCreateNewAIChatNotifier.value =
            mobileCreateNewAIChatNotifier.value + 1;
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        margin: EdgeInsets.only(top: 16),
        padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Row(
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
        ),
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
        style: theme.textStyle.heading4
            .standard(color: theme.textColorScheme.primary),
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
              style: theme.textStyle.heading4
                  .standard(color: theme.textColorScheme.primary),
            ),
            TextSpan(
              text: ' "$queryText"',
              style: theme.textStyle.heading4
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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      margin: EdgeInsets.only(top: 8),
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
              style: context.searchSubtitleStyle,
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
    final summaries = _mockSummary ?? state?.resultSummaries ?? [];
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VSpace(8),
          buildHeader(context),
          VSpace(12),
          LayoutBuilder(
            builder: (context, constrains) {
              final summary = summaries.first;
              return MobileSearchSummaryCell(
                key: ValueKey(summary.content.trim()),
                summary: summary,
                maxWidth: constrains.maxWidth,
                theme: AppFlowyTheme.of(context),
                textStyle: context.searchTitleStyle,
              );
            },
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
            style: context.searchSubtitleStyle,
          ),
        ],
      ),
    );
  }
}

List<SearchSummaryPB>? _mockSummary;

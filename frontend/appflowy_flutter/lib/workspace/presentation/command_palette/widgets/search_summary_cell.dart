import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/presentation/message/ai_markdown_text.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchSummaryCell extends StatelessWidget {
  const SearchSummaryCell({
    required this.summary,
    required this.isHovered,
    super.key,
  });

  final SearchSummaryPB summary;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      isSelected: () => isHovered,
      onHover: (value) {
        context.read<SearchResultListBloc>().add(
              SearchResultListEvent.onHoverSummary(
                summary: summary,
                userHovered: true,
              ),
            );
      },
      style: HoverStyle(
        borderRadius: BorderRadius.circular(8),
        hoverColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        foregroundColorOnHover: AFThemeExtension.of(context).textColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: FlowyText(
          summary.content,
          maxLines: 20,
        ),
      ),
    );
  }
}

class SearchSummaryPreview extends StatelessWidget {
  const SearchSummaryPreview({
    required this.summary,
    super.key,
  });

  final SearchSummaryPB summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.highlights.isNotEmpty) ...[
          Opacity(
            opacity: 0.5,
            child: FlowyText(
              LocaleKeys.commandPalette_aiOverviewMoreDetails.tr(),
              fontSize: 12,
            ),
          ),
          const VSpace(6),
          SearchSummaryHighlight(text: summary.highlights),
          const VSpace(36),
        ],

        Opacity(
          opacity: 0.5,
          child: FlowyText(
            LocaleKeys.commandPalette_aiOverviewSource.tr(),
            fontSize: 12,
          ),
        ),
        // Sources
        const VSpace(6),
        ...summary.sources.map((e) => SearchSummarySource(source: e)),
      ],
    );
  }
}

class SearchSummaryHighlight extends StatelessWidget {
  const SearchSummaryHighlight({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return AIMarkdownText(markdown: text);
  }
}

class SearchSummarySource extends StatelessWidget {
  const SearchSummarySource({
    required this.source,
    super.key,
  });

  final SearchSourcePB source;

  @override
  Widget build(BuildContext context) {
    final icon = source.icon.getIcon();
    return FlowyTooltip(
      message: LocaleKeys.commandPalette_clickToOpenPage.tr(),
      child: SizedBox(
        height: 30,
        child: FlowyButton(
          leftIcon: icon,
          hoverColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          text: FlowyText(source.displayName),
          onTap: () {
            context.read<SearchResultListBloc>().add(
                  SearchResultListEvent.openPage(pageId: source.id),
                );
          },
        ),
      ),
    );
  }
}

import 'package:appflowy/generated/locale_keys.g.dart';
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
    super.key,
  });

  final SearchSummaryPB summary;

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      onHover: (value) {
        context.read<SearchResultListBloc>().add(
              SearchResultListEvent.onHoverSummary(summary: summary),
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
          maxLines: 3,
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
        FlowyText(LocaleKeys.commandPalette_aiOverviewSource.tr()),
        const Divider(
          thickness: 1,
        ),
        const VSpace(6),
        ...summary.sources.map((e) => SearchSummarySource(source: e)),
      ],
    );
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
    return Row(
      children: [
        if (icon != null) ...[
          SizedBox(width: 24, child: icon),
          const HSpace(6),
        ],
        FlowyText(source.displayName),
      ],
    );
  }
}

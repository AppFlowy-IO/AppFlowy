import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SearchResultList extends StatelessWidget {
  const SearchResultList({
    required this.trash,
    required this.resultItems,
    required this.resultSummaries,
    super.key,
  });

  final List<TrashPB> trash;
  final List<SearchResponseItemPB> resultItems;
  final List<SearchSummaryPB> resultSummaries;

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8) +
            const EdgeInsets.only(left: 8),
        child: Opacity(
          opacity: 0.6,
          child: FlowyText(title, fontSize: 12),
        ),
      );

  Widget _buildSummariesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LocaleKeys.commandPalette_aiSummary.tr()),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: resultSummaries.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, index) => SearchSummaryTile(
            summary: resultSummaries[index],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSectionHeader(LocaleKeys.commandPalette_bestMatches.tr()),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: resultItems.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, index) {
            final item = resultItems[index];
            return SearchResultTile(
              item: item,
              onSelected: () => FlowyOverlay.pop(context),
              isTrashed: trash.any((t) => t.id == item.viewId),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          if (resultSummaries.isNotEmpty) _buildSummariesSection(),
          const VSpace(10),
          if (resultItems.isNotEmpty) _buildResultsSection(context),
        ],
      ),
    );
  }
}

class SearchSummaryTile extends StatelessWidget {
  const SearchSummaryTile({required this.summary, super.key});

  final SearchSummaryPB summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FlowyText(
        summary.content,
        maxLines: 10,
      ),
    );
  }
}

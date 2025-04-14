import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_result_cell.dart';
import 'search_summary_cell.dart';

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
        _buildSectionHeader(LocaleKeys.commandPalette_aiOverview.tr()),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: resultSummaries.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, index) => SearchSummaryCell(
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
            return SearchResultCell(
              item: item,
              onSelected: () => FlowyOverlay.pop(context),
              isTrashed: trash.any((t) => t.id == item.id),
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
      child: BlocProvider(
        create: (context) => SearchResultListBloc(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 7,
              child: ListView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  if (resultSummaries.isNotEmpty) _buildSummariesSection(),
                  const VSpace(10),
                  if (resultItems.isNotEmpty) _buildResultsSection(context),
                ],
              ),
            ),
            const HSpace(10),
            Flexible(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: const SearchCellPreview(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchCellPreview extends StatelessWidget {
  const SearchCellPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchResultListBloc, SearchResultListState>(
      builder: (context, state) {
        if (state.hoveredSummary != null) {
          return SearchSummaryPreview(summary: state.hoveredSummary!);
        } else if (state.hoveredResult != null) {
          return SearchResultPreview(data: state.hoveredResult!);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

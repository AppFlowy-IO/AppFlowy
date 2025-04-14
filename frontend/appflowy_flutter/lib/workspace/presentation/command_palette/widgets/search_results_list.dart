import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_result_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SearchResultList extends StatefulWidget {
  const SearchResultList({
    required this.trash,
    required this.resultItems,
    required this.resultSummaries,
    super.key,
  });

  final List<TrashPB> trash;
  final List<SearchResponseItemPB> resultItems;
  final List<SearchSummaryPB> resultSummaries;

  @override
  State<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<SearchResultList> {
  dynamic _selectedCellData;

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8) +
            const EdgeInsets.only(left: 8),
        child: Opacity(
          opacity: 0.6,
          child: FlowyText(title, fontSize: 12),
        ),
      );

  void _onHoverSummary(SearchSummaryPB summary) {
    setState(() {
      _selectedCellData = summary;
    });
  }

  void _onHoverResult(SearchResponseItemPB item) {
    setState(() {
      _selectedCellData = item;
    });
  }

  Widget _buildSummariesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(LocaleKeys.commandPalette_aiSummary.tr()),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: widget.resultSummaries.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, index) => SearchSummaryCell(
            summary: widget.resultSummaries[index],
            onHover: _onHoverSummary,
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
          itemCount: widget.resultItems.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, index) {
            final item = widget.resultItems[index];
            return SearchResultCell(
              item: item,
              onSelected: () => FlowyOverlay.pop(context),
              isTrashed: widget.trash.any((t) => t.id == item.viewId),
              onHover: _onHoverResult,
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
      child: Row(
        children: [
          Flexible(
            flex: 7,
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                if (widget.resultSummaries.isNotEmpty) _buildSummariesSection(),
                const VSpace(10),
                if (widget.resultItems.isNotEmpty)
                  _buildResultsSection(context),
              ],
            ),
          ),
          Flexible(
            flex: 3,
            child: SearchCellDetail(cellData: _selectedCellData),
          ),
        ],
      ),
    );
  }
}

class SearchCellDetail extends StatelessWidget {
  const SearchCellDetail({
    super.key,
    required this.cellData,
  });

  final dynamic cellData;

  @override
  Widget build(BuildContext context) {
    if (cellData == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: FlowyText(
            'Hover over an item to see details',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (cellData is SearchSummaryPB) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FlowyText(
              'AI Summary',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            const VSpace(8),
            FlowyText(
              cellData.content,
              fontSize: 12,
            ),
          ],
        ),
      );
    }

    if (cellData is SearchResponseItemPB) {
      final item = cellData as SearchResponseItemPB;
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText(
              item.data,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            const VSpace(8),
            if (item.preview.isNotEmpty)
              FlowyText(
                item.preview,
                fontSize: 12,
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class SearchSummaryCell extends StatefulWidget {
  const SearchSummaryCell({
    required this.summary,
    required this.onHover,
    super.key,
  });

  final SearchSummaryPB summary;
  final Function(SearchSummaryPB) onHover;

  @override
  State<SearchSummaryCell> createState() => _SearchSummaryCellState();
}

class _SearchSummaryCellState extends State<SearchSummaryCell> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(widget.summary),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: FlowyText(
          widget.summary.content,
          maxLines: 3,
        ),
      ),
    );
  }
}

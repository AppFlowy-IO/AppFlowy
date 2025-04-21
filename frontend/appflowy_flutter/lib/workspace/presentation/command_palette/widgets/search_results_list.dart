import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'search_result_cell.dart';
import 'search_summary_cell.dart';

class SearchResultList extends StatefulWidget {
  const SearchResultList({
    required this.trash,
    required this.resultItems,
    required this.resultSummaries,
    super.key,
  });

  final List<TrashPB> trash;
  final List<SearchResultItem> resultItems;
  final List<SearchSummaryPB> resultSummaries;

  @override
  State<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<SearchResultList> {
  late final SearchResultListBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = SearchResultListBloc();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8) +
            const EdgeInsets.only(left: 8),
        child: Opacity(
          opacity: 0.6,
          child: FlowyText(title, fontSize: 12),
        ),
      );

  Widget _buildAIOverviewSection(BuildContext context) {
    final state = context.read<CommandPaletteBloc>().state;

    if (state.generatingAIOverview) {
      return Row(
        children: [
          _buildSectionHeader(LocaleKeys.commandPalette_aiOverview.tr()),
          const HSpace(10),
          const AIOverviewIndicator(),
        ],
      );
    }

    if (widget.resultSummaries.isNotEmpty) {
      if (!bloc.state.userHovered) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            bloc.add(
              SearchResultListEvent.onHoverSummary(
                summary: widget.resultSummaries[0],
                userHovered: false,
              ),
            );
          },
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(LocaleKeys.commandPalette_aiOverview.tr()),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.resultSummaries.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, index) => SearchSummaryCell(
              summary: widget.resultSummaries[index],
              isHovered: bloc.state.hoveredSummary != null,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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
              isTrashed: widget.trash.any((t) => t.id == item.id),
              isHovered: bloc.state.hoveredResult?.id == item.id,
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
      child: BlocProvider.value(
        value: bloc,
        child: BlocListener<SearchResultListBloc, SearchResultListState>(
          listener: (context, state) {
            if (state.openPageId != null) {
              FlowyOverlay.pop(context);
              getIt<ActionNavigationBloc>().add(
                ActionNavigationEvent.performAction(
                  action: NavigationAction(objectId: state.openPageId!),
                ),
              );
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 7,
                child: BlocBuilder<SearchResultListBloc, SearchResultListState>(
                  buildWhen: (previous, current) =>
                      previous.hoveredResult != current.hoveredResult ||
                      previous.hoveredSummary != current.hoveredSummary,
                  builder: (context, state) {
                    return ListView(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      children: [
                        _buildAIOverviewSection(context),
                        const VSpace(10),
                        if (widget.resultItems.isNotEmpty)
                          _buildResultsSection(context),
                      ],
                    );
                  },
                ),
              ),
              const HSpace(10),
              if (widget.resultItems
                  .any((item) => item.content.isNotEmpty)) ...[
                const VerticalDivider(
                  thickness: 1.0,
                ),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: const SearchCellPreview(),
                  ),
                ),
              ],
            ],
          ),
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

class AIOverviewIndicator extends StatelessWidget {
  const AIOverviewIndicator({
    super.key,
    this.duration = const Duration(seconds: 1),
  });

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final slice = Duration(milliseconds: duration.inMilliseconds ~/ 5);
    return SelectionContainer.disabled(
      child: SizedBox(
        height: 20,
        width: 100,
        child: SeparatedRow(
          separatorBuilder: () => const HSpace(4),
          children: [
            buildDot(const Color(0xFF9327FF))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice, begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0)
                .then()
                .slideY(duration: slice * 2, begin: 0, end: 0),
            buildDot(const Color(0xFFFB006D))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice, begin: 0, end: 0)
                .then()
                .slideY(begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0)
                .then()
                .slideY(begin: 0, end: 0),
            buildDot(const Color(0xFFFFCE00))
                .animate(onPlay: (controller) => controller.repeat())
                .slideY(duration: slice * 2, begin: 0, end: 0)
                .then()
                .slideY(duration: slice, begin: 0, end: -1)
                .then()
                .slideY(begin: -1, end: 1)
                .then()
                .slideY(begin: 1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget buildDot(Color color) {
    return SizedBox.square(
      dimension: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

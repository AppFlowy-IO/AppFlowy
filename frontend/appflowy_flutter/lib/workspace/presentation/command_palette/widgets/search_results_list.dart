import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/navigation_bloc_extension.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_ask_ai_entrance.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'page_preview.dart';
import 'search_result_cell.dart';

class SearchResultList extends StatefulWidget {
  const SearchResultList({
    required this.cachedViews,
    required this.resultItems,
    required this.resultSummaries,
    super.key,
  });

  final Map<String, ViewPB> cachedViews;
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocListener<SearchResultListBloc, SearchResultListState>(
        listener: (context, state) {
          final pageId = state.openPageId;
          if (pageId != null && pageId.isNotEmpty) {
            FlowyOverlay.pop(context);
            pageId.navigateTo();
          }
        },
        child: BlocBuilder<SearchResultListBloc, SearchResultListState>(
          builder: (context, state) {
            final hasHoverResult = state.hoveredResult != null;
            return LayoutBuilder(
              builder: (context, constrains) {
                final maxWidth = constrains.maxWidth;
                final hidePreview = maxWidth < 884;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildResultsSection(context, hidePreview)),
                    if (!hidePreview && hasHoverResult)
                      const SearchCellPreview(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      child: Text(
        LocaleKeys.commandPalette_bestMatches.tr(),
        style: theme.textStyle.body
            .enhanced(color: theme.textColorScheme.secondary)
            .copyWith(
              letterSpacing: 0.2,
              height: 22 / 16,
            ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, bool hidePreview) {
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    if (widget.resultItems.isEmpty) return const SizedBox.shrink();
    List<SearchResultItem> resultItems = widget.resultItems;
    final hasCachedViews = widget.cachedViews.isNotEmpty;
    if (hasCachedViews) {
      resultItems = widget.resultItems
          .where((item) => widget.cachedViews[item.id] != null)
          .toList();
    }
    return ScrollControllerBuilder(
      builder: (context, controller) {
        final hoveredId = bloc.state.hoveredResult?.id;
        return Padding(
          padding: EdgeInsets.only(right: hidePreview ? 0 : 6),
          child: FlowyScrollbar(
            controller: controller,
            thumbVisibility: false,
            child: SingleChildScrollView(
              controller: controller,
              physics: ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  right: hidePreview ? 0 : 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAskingAI) SearchAskAiEntrance(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSectionHeader(context),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: resultItems.length,
                          itemBuilder: (_, index) {
                            final item = resultItems[index];
                            return SearchResultCell(
                              key: ValueKey(item.id),
                              item: item,
                              isNarrowWindow: hidePreview,
                              view: widget.cachedViews[item.id],
                              isHovered: hoveredId == item.id,
                              query: context
                                  .read<CommandPaletteBloc?>()
                                  ?.state
                                  .query,
                            );
                          },
                        ),
                        VSpace(16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchCellPreview extends StatelessWidget {
  const SearchCellPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchResultListBloc, SearchResultListState>(
      builder: (context, state) {
        final hoverdId = state.hoveredResult?.id ?? '';
        final commandPaletteState = context.read<CommandPaletteBloc>().state;
        final view = commandPaletteState.cachedViews[hoverdId];
        if (view != null) {
          return SearchResultPreview(view: view);
        }
        return SomethingWentWrong();
      },
    );
  }
}

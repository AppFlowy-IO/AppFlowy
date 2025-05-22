import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_ask_ai_entrance.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_special_styles.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          if (state.openPageId != null) {
            FlowyOverlay.pop(context);
            getIt<ActionNavigationBloc>().add(
              ActionNavigationEvent.performAction(
                action: NavigationAction(objectId: state.openPageId!),
              ),
            );
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
        style: context.searchPanelTitle1,
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, bool hidePreview) {
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    if (widget.resultItems.isEmpty) return const SizedBox.shrink();
    final resultItems = widget.resultItems
        .where((item) => widget.cachedViews[item.id] != null)
        .toList();
    return ScrollControllerBuilder(
      builder: (context, controller) {
        final hoveredId = bloc.state.hoveredResult?.id;
        return Padding(
          padding: EdgeInsets.only(right: hidePreview ? 0 : 6),
          child: FlowyScrollbar(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              physics: ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(right: hidePreview ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAskingAI) SearchAskAiEntrance(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSectionHeader(context),
                        VSpace(8),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (_, index) {
                            final item = resultItems[index];
                            final isHovered = hoveredId == item.id;
                            if (isHovered) return VSpace(1);
                            if (index < resultItems.length - 1) {
                              final nextView = resultItems[index + 1];
                              final isNextHovered = hoveredId == nextView.id;
                              if (isNextHovered) return VSpace(1);
                            }
                            return const AFDivider();
                          },
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
        return const SizedBox.shrink();
      },
    );
  }
}

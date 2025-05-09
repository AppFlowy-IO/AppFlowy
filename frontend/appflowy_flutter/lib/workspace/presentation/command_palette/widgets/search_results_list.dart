import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_list_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_ask_ai_entrance.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_result_cell.dart';

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
            final showPreview = state.hoveredResult != null;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(flex: 2, child: _buildResultsSection(context)),
                if (showPreview) ...[
                  AFDivider(axis: Axis.vertical),
                  Flexible(child: const SearchCellPreview()),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        LocaleKeys.commandPalette_bestMatches.tr(),
        style: theme.textStyle.body.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    if (widget.resultItems.isEmpty) return const SizedBox.shrink();
    final trashIds = widget.trash.map((e) => e.id).toSet();
    final resultItems = widget.resultItems
        .where((item) => !trashIds.contains(item.id))
        .toList();
    return ScrollControllerBuilder(
      builder: (context, controller) {
        return FlowyScrollbar(
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            physics: ClampingScrollPhysics(),
            child: Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showAskingAI) SearchAskAiEntrance(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context),
                        VSpace(8),
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: resultItems.length,
                          separatorBuilder: (_, __) => AFDivider(),
                          itemBuilder: (_, index) {
                            final item = resultItems[index];
                            return SearchResultCell(
                              item: item,
                              isHovered:
                                  bloc.state.hoveredResult?.id == item.id,
                              query: context
                                  .read<CommandPaletteBloc?>()
                                  ?.state
                                  .query,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
        if (state.hoveredResult != null) {
          return SearchResultPreview(item: state.hoveredResult!);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/navigation_bloc_extension.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_recent_view_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'keyboard_scroller.dart';
import 'page_preview.dart';
import 'search_ask_ai_entrance.dart';
import 'search_field.dart';

class RecentViewsList extends StatelessWidget {
  const RecentViewsList({super.key, required this.onSelected});

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          final recentViews = state.views.map((e) => e.item).toSet().toList();
          final bloc = context.read<RecentViewsBloc>();
          return LayoutBuilder(
            builder: (context, constrains) {
              final maxWidth = constrains.maxWidth;
              final hidePreview = maxWidth < 884;
              final commandPaletteState =
                  context.read<CommandPaletteBloc>().state;
              return ScrollControllerBuilder(
                builder: (context, controller) {
                  return KeyboardScroller<ViewPB>(
                    onSelect: (index) {
                      bloc.add(RecentViewsEvent.hoverView(recentViews[index]));
                    },
                    onConfirm: (index) {
                      recentViews[index].id.navigateTo();
                      onSelected();
                    },
                    idGetter: (item) => item.id,
                    list: recentViews,
                    controller: controller,
                    selectedIndexGetter: () => recentViews.indexWhere(
                      (item) => item.id == bloc.state.hoveredView?.id,
                    ),
                    builder: (context, detectors) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SearchField(
                            query: commandPaletteState.query,
                            isLoading: commandPaletteState.searching,
                          ),
                          Flexible(
                            child: Row(
                              children: [
                                buildLeftPanel(
                                  state: state,
                                  context: context,
                                  hidePreview: hidePreview,
                                  controller: controller,
                                  detectors: detectors,
                                ),
                                if (!hidePreview) buildPreview(state),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget buildLeftPanel({
    required RecentViewsState state,
    required BuildContext context,
    required bool hidePreview,
    required ScrollController controller,
    required AreaDetectors detectors,
  }) {
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    return Flexible(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(right: hidePreview ? 0 : 6),
          child: FlowyScrollbar(
            controller: controller,
            thumbVisibility: false,
            child: SingleChildScrollView(
              controller: controller,
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  right: hidePreview ? 0 : 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showAskingAI) SearchAskAiEntrance(),
                    buildTitle(context),
                    buildViewList(
                      state: state,
                      context: context,
                      hidePreview: hidePreview,
                      detectors: detectors,
                    ),
                    VSpace(16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      child: Text(
        LocaleKeys.sideBar_recent.tr(),
        style: theme.textStyle.body
            .enhanced(color: theme.textColorScheme.secondary)
            .copyWith(
              letterSpacing: 0.2,
              height: 22 / 16,
            ),
      ),
    );
  }

  Widget buildViewList({
    required RecentViewsState state,
    required BuildContext context,
    required bool hidePreview,
    required AreaDetectors detectors,
  }) {
    final recentViews = state.views.map((e) => e.item).toSet().toList();

    if (recentViews.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentViews.length,
      itemBuilder: (_, index) {
        final view = recentViews[index];

        return SearchRecentViewCell(
          key: ValueKey(view.id),
          icon: SizedBox.square(
            dimension: 20,
            child: Center(child: view.buildIcon(context)),
          ),
          view: view,
          onSelected: onSelected,
          isNarrowWindow: hidePreview,
          detectors: detectors,
        );
      },
    );
  }

  Widget buildPreview(RecentViewsState state) {
    final hoveredView = state.hoveredView;
    if (hoveredView == null) {
      return SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topLeft,
      child: PagePreview(
        key: ValueKey(hoveredView.id),
        view: hoveredView,
        onViewOpened: () {
          hoveredView.id.navigateTo();
          onSelected();
        },
      ),
    );
  }
}

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/command_palette/navigation_bloc_extension.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_recent_view_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'page_preview.dart';
import 'search_ask_ai_entrance.dart';

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
          return LayoutBuilder(
            builder: (context, constrains) {
              final maxWidth = constrains.maxWidth;
              final hidePreview = maxWidth < 884;
              return Row(
                children: [
                  buildLeftPanel(state, context, hidePreview),
                  if (!hidePreview) buildPreview(state),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget buildLeftPanel(
    RecentViewsState state,
    BuildContext context,
    bool hidePreview,
  ) {
    final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
    final showAskingAI =
        workspaceState?.userProfile.workspaceType == WorkspaceTypePB.ServerW;
    return Flexible(
      child: Align(
        alignment: Alignment.topLeft,
        child: ScrollControllerBuilder(
          builder: (context, controller) {
            return Padding(
              padding: EdgeInsets.only(right: hidePreview ? 0 : 6),
              child: FlowyScrollbar(
                controller: controller,
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
                        buildViewList(state, context, hidePreview),
                        VSpace(8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
        style: theme.textStyle.heading4
            .enhanced(color: theme.textColorScheme.secondary)
            .copyWith(
              letterSpacing: 0.2,
              height: 24 / 16,
            ),
      ),
    );
  }

  Widget buildViewList(
    RecentViewsState state,
    BuildContext context,
    bool hidePreview,
  ) {
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

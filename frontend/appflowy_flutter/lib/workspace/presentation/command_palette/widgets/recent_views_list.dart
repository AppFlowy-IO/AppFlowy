import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_recent_view_cell.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_special_styles.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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
          // We remove duplicates by converting the list to a set first
          final List<ViewPB> recentViews =
              state.views.map((e) => e.item).toSet().toList();
          final theme = AppFlowyTheme.of(context);
          final workspaceState = context.read<UserWorkspaceBloc?>()?.state;
          final showAskingAI = workspaceState?.userProfile.workspaceType ==
              WorkspaceTypePB.ServerW;
          final hoveredView = state.hoveredView;
          return Row(
            children: [
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ScrollControllerBuilder(
                    builder: (context, controller) {
                      return FlowyScrollbar(
                        controller: controller,
                        child: SingleChildScrollView(
                          controller: controller,
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showAskingAI) SearchAskAiEntrance(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: theme.spacing.m,
                                  vertical: theme.spacing.s,
                                ),
                                child: Text(
                                  LocaleKeys.sideBar_recent.tr(),
                                  style: context.searchPanelTitle1,
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentViews.length,
                                itemBuilder: (_, index) {
                                  final view = recentViews[index];

                                  final icon = view.icon.value.isNotEmpty
                                      ? RawEmojiIconWidget(
                                          emoji: view.icon.toEmojiIconData(),
                                          emojiSize: 16.0,
                                          lineHeight: 20 / 16,
                                        )
                                      : FlowySvg(
                                          view.iconData,
                                          size: const Size.square(20),
                                          color:
                                              theme.iconColorScheme.secondary,
                                        );

                                  return SearchRecentViewCell(
                                    icon: icon,
                                    view: view,
                                    onSelected: onSelected,
                                  );
                                },
                              ),
                              VSpace(8),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (hoveredView != null) ...[
                AFDivider(axis: Axis.vertical),
                Flexible(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: PagePreview(
                      view: hoveredView,
                      onViewOpened: () {
                        getIt<ActionNavigationBloc>().add(
                          ActionNavigationEvent.performAction(
                            action: NavigationAction(
                              objectId: hoveredView.id,
                            ),
                          ),
                        );
                        onSelected();
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

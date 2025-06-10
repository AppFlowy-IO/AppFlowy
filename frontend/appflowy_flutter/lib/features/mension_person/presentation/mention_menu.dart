import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'widgets/date_reminder_list.dart';
import 'widgets/mention_menu_scroller.dart';
import 'widgets/mention_menu_shortcuts.dart';
import 'widgets/page_list.dart';
import 'widgets/person/person_list.dart';

class MentionMenu extends StatelessWidget {
  const MentionMenu({
    super.key,
    this.width = 400,
    this.maxHeight = 400,
  });
  final double width;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return BlocProvider(
      create: (_) => MentionBloc(MockMentionRepository(), workspaceId),
      child: BlocBuilder<MentionBloc, MentionState>(
        builder: (context, state) {
          final itemMap = MentionItemMap();
          return Provider<MentionItemMap>.value(
            value: itemMap,
            child: MentionMenuScroller(
              builder: (_, controller) {
                return BlocListener<MentionBloc, MentionState>(
                  listener: (context, state) {
                    if (!controller.hasClients || !context.mounted) return;
                    controller.jumpTo(0);
                  },
                  listenWhen: (previous, current) =>
                      previous.query != current.query,
                  child: MentionMenuShortcuts(
                    scrollController: controller,
                    itemMap: itemMap,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: AFMenu(
                        width: width,
                        padding: EdgeInsets.zero,
                        builder: (context, children) {
                          return FlowyScrollbar(
                            controller: controller,
                            child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: children,
                              ),
                            ),
                          );
                        },
                        children: [
                          PersonList(),
                          PageList(),
                          DateReminderList(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

extension MentionMenuItemBackgroundColor on BuildContext {
  Color mentionItemBGColor(
    BuildContext context,
    bool isHovering,
    bool selected,
    bool disabled,
  ) {
    final theme = AppFlowyTheme.of(this);
    return isHovering || selected
        ? theme.fillColorScheme.contentHover
        : theme.fillColorScheme.content;
  }
}

import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/startup/startup.dart';
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

typedef MentionChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

class MentionMenu extends StatelessWidget {
  const MentionMenu({
    super.key,
    this.query = '',
    this.width = 400,
    this.maxHeight = 400,
    this.builder,
    required this.sendNotification,
  });
  final double width;
  final double maxHeight;
  final String query;
  final bool sendNotification;
  final MentionChildBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final workspaceId =
        context.read<UserWorkspaceBloc>().state.currentWorkspace?.workspaceId ??
            '';
    return BlocProvider(
      create: (_) => MentionBloc(
        repository: MockMentionRepository(),
        workspaceId: workspaceId,
        query: query,
        sendNotification: sendNotification,
        personListCache: getIt<PersonListCache>(),
      )..add(MentionEvent.init()),
      child: BlocBuilder<MentionBloc, MentionState>(
        builder: (context, state) {
          final itemMap = MentionItemMap();
          final child = Provider<MentionItemMap>.value(
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
                    child: buildMenu(context, controller),
                  ),
                );
              },
            ),
          );
          return builder?.call(context, child) ?? child;
        },
      ),
    );
  }

  Widget buildMenu(BuildContext context, ScrollController controller) {
    final theme = AppFlowyTheme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceColorScheme.primary,
          borderRadius: BorderRadius.circular(theme.borderRadius.l),
          border: Border.all(
            color: theme.borderColorScheme.primary,
          ),
          boxShadow: theme.shadow.medium,
        ),
        width: width,
        padding: EdgeInsets.zero,
        child: FlowyScrollbar(
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PersonList(),
                PageList(),
                DateReminderList(),
              ],
            ),
          ),
        ),
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

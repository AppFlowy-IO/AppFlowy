import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/gesture.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.tabType,
    required this.reminder,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppearanceSettingsCubit>().state;
    final dateFormate = settings.dateFormat;
    final timeFormate = settings.timeFormat;
    return BlocProvider<NotificationReminderBloc>(
      create: (context) => NotificationReminderBloc()
        ..add(
          NotificationReminderEvent.initial(
            reminder,
            dateFormate,
            timeFormate,
          ),
        ),
      child: BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
        builder: (context, state) {
          if (state.status == NotificationReminderStatus.loading ||
              state.status == NotificationReminderStatus.initial) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationReminderStatus.error) {
            // error handle.
            return const SizedBox.shrink();
          }

          return AnimatedGestureDetector(
            scaleFactor: 0.99,
            onTapUp: () {
              context.read<ReminderBloc>().add(
                    ReminderEvent.update(
                      ReminderUpdate(id: reminder.id, isRead: true),
                    ),
                  );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _SlidableNotificationItem(
                tabType: tabType,
                reminder: reminder,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HSpace(8.0),
                    !reminder.isRead
                        ? const _UnreadRedDot()
                        : const HSpace(6.0),
                    const HSpace(4.0),
                    _NotificationIcon(reminder: reminder),
                    const HSpace(12.0),
                    Expanded(
                      child: _NotificationContent(reminder: reminder),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlidableNotificationItem extends StatelessWidget {
  const _SlidableNotificationItem({
    required this.tabType,
    required this.reminder,
    required this.child,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // only show the actions in the inbox tab

    final List<NotificationPaneActionType> actions = switch (tabType) {
      MobileNotificationTabType.inbox => [
          NotificationPaneActionType.more,
          NotificationPaneActionType.markAsRead,
        ],
      MobileNotificationTabType.unread => [],
      MobileNotificationTabType.archive => [
          if (kDebugMode) NotificationPaneActionType.unArchive,
        ],
    };

    if (actions.isEmpty) {
      return child;
    }

    final children = actions
        .map(
          (action) => action.actionButton(
            context,
            tabType: tabType,
          ),
        )
        .toList();

    final extentRatio = actions.length == 1 ? 1 / 5 : 1 / 3;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: extentRatio,
        children: children,
      ),
      child: child,
    );
  }
}

const _kNotificationIconHeight = 36.0;

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return const FlowySvg(
      FlowySvgs.m_notification_reminder_s,
      size: Size.square(_kNotificationIconHeight),
      blendMode: null,
    );
  }
}

class _UnreadRedDot extends StatelessWidget {
  const _UnreadRedDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _kNotificationIconHeight,
      child: Center(
        child: SizedBox.square(
          dimension: 6.0,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Color(0xFFFF6331),
              shape: OvalBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // title
            _buildHeader(),

            // time & page name
            _buildTimeAndPageName(state.createdAt, state.pageTitle),

            // content
            IntrinsicHeight(
              child: BlocProvider(
                create: (context) => DocumentPageStyleBloc(view: state.view!),
                child: _NotificationDocumentContent(nodes: state.nodes),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return const FlowyText.semibold(
      'Reminder',
      fontSize: 14,
      figmaLineHeight: 20,
    );
  }

  Widget _buildTimeAndPageName(String createdAt, String pageTitle) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          // the legacy reminder doesn't contain the timestamp, so we don't show it
          if (createdAt.isNotEmpty) ...[
            FlowyText.regular(
              createdAt,
              fontSize: 12,
              figmaLineHeight: 18,
              color: const Color(0xFF171717),
            ),
            const _Ellipse(),
          ],
          FlowyText.regular(
            pageTitle,
            fontSize: 12,
            figmaLineHeight: 18,
            color: const Color(0xFF171717),
          ),
        ],
      ),
    );
  }
}

class _Ellipse extends StatelessWidget {
  const _Ellipse();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2.50,
      height: 2.50,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: const ShapeDecoration(
        color: Color(0xFF171717),
        shape: OvalBorder(),
      ),
    );
  }
}

class _NotificationDocumentContent extends StatefulWidget {
  const _NotificationDocumentContent({
    required this.nodes,
  });

  final List<Node> nodes;

  @override
  State<_NotificationDocumentContent> createState() =>
      _NotificationDocumentContentState();
}

class _NotificationDocumentContentState
    extends State<_NotificationDocumentContent> {
  late final styleCustomizer = EditorStyleCustomizer(
    context: context,
    padding: EdgeInsets.zero,
  );

  late final editorStyle = styleCustomizer.style().copyWith(
        // hide the cursor
        cursorColor: Colors.transparent,
        cursorWidth: 0,
        textStyleConfiguration: const TextStyleConfiguration(
          text: TextStyle(
            fontSize: 14,
            color: Color(0xFF171717),
            height: 22 / 14,
            fontWeight: FontWeight.w400,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final editorState = EditorState(
      document: Document(
        root: pageNode(children: widget.nodes),
      ),
    );

    final blockBuilders = getEditorBuilderMap(
      context: context,
      editorState: editorState,
      styleCustomizer: styleCustomizer,
      // the editor is not editable in the chat
      editable: false,
    );

    return AppFlowyEditor(
      editorState: editorState,
      editorStyle: editorStyle,
      editable: false,
      shrinkWrap: true,
      blockComponentBuilders: blockBuilders,
    );
  }
}

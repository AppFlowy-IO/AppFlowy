import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notifications_hub_empty.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.shownReminders,
    required this.reminderBloc,
    required this.views,
    this.isUpcoming = false,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
    this.actionBar,
  });

  final List<ReminderPB> shownReminders;
  final ReminderBloc reminderBloc;
  final List<ViewPB> views;
  final bool isUpcoming;
  final Function(ReminderPB reminder)? onAction;
  final Function(ReminderPB reminder)? onDelete;
  final Function(ReminderPB reminder, bool isRead)? onReadChanged;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    if (shownReminders.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (actionBar != null) actionBar!,
          const Expanded(child: NotificationsHubEmpty()),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (actionBar != null) actionBar!,
          ...shownReminders.map(
            (ReminderPB reminder) {
              final blockId = reminder.meta[ReminderMetaKeys.blockId.name];

              Future<Node?>? nodeBuilder;
              if (blockId != null) {
                nodeBuilder = _getNodeFromBlockId(reminder.objectId, blockId);
              }

              return NotificationItem(
                reminderId: reminder.id,
                key: ValueKey(reminder.id),
                title: reminder.title,
                scheduled: reminder.scheduledAt,
                body: reminder.message,
                block: nodeBuilder,
                isRead: reminder.isRead,
                includeTime: reminder.includeTime ?? false,
                readOnly: isUpcoming,
                onReadChanged: (isRead) =>
                    onReadChanged?.call(reminder, isRead),
                onDelete: () => onDelete?.call(reminder),
                onAction: () => onAction?.call(reminder),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Node?> _getNodeFromBlockId(String viewId, String blockId) async {
    final blockOrFailure = await DocumentService().getBlockFromDocument(
      viewId: viewId,
      blockId: blockId,
    );

    return blockOrFailure.fold(
      (_) => null,
      (block) => block.toNode(meta: MetaPB()),
    );
  }
}

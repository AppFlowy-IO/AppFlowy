import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notifications_hub_empty.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

/// Displays a Lsit of Notifications, currently used primarily to
/// display Reminders.
///
/// Optimized for both Mobile & Desktop use
///
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
  final Function(ReminderPB reminder, int? path, ViewPB? view)? onAction;
  final Function(ReminderPB reminder)? onDelete;
  final Function(ReminderPB reminder, bool isRead)? onReadChanged;
  final Widget? actionBar;

  @override
  Widget build(BuildContext context) {
    if (shownReminders.isEmpty) {
      return Column(
        children: [
          if (actionBar != null) actionBar!,
          const Expanded(child: NotificationsHubEmpty()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actionBar != null) actionBar!,
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...shownReminders.map(
                  (ReminderPB reminder) {
                    final blockId = reminder.meta[ReminderMetaKeys.blockId];

                    final documentService = DocumentService();
                    final documentFuture = documentService.openDocument(
                      viewId: reminder.objectId,
                    );

                    Future<Node?>? nodeBuilder;
                    if (blockId != null) {
                      nodeBuilder =
                          _getNodeFromDocument(documentFuture, blockId);
                    }

                    final view = views.findView(reminder.objectId);
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
                      onAction: (path) => onAction?.call(reminder, path, view),
                      view: view,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Node?> _getNodeFromDocument(
    Future<FlowyResult<DocumentDataPB, FlowyError>> documentFuture,
    String blockId,
  ) async {
    final document = (await documentFuture).fold(
      (document) => document,
      (_) => null,
    );

    if (document == null) {
      return null;
    }

    final rootNode = document.toDocument()?.root;
    if (rootNode == null) {
      return null;
    }

    return _searchById(rootNode, blockId);
  }
}

/// Recursively iterates a [Node] and compares by its [id]
///
Node? _searchById(Node current, String id) {
  if (current.id == id) {
    return current;
  }

  if (current.children.isNotEmpty) {
    for (final child in current.children) {
      final node = _searchById(child, id);

      if (node != null) {
        return node;
      }
    }
  }

  return null;
}

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notifications_hub_empty.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart';
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
  final Function(ReminderPB reminder, int? path)? onAction;
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

              final documentService = DocumentService();
              final documentFuture = documentService.openDocument(
                viewId: reminder.objectId,
              );

              Future<Node?>? nodeBuilder;
              Future<int?>? pathFinder;
              if (blockId != null) {
                nodeBuilder = _getNodeFromDocument(documentFuture, blockId);
                pathFinder = _getPathFromDocument(documentFuture, blockId);
              }

              return NotificationItem(
                reminderId: reminder.id,
                key: ValueKey(reminder.id),
                title: reminder.title,
                scheduled: reminder.scheduledAt,
                body: reminder.message,
                path: pathFinder,
                block: nodeBuilder,
                isRead: reminder.isRead,
                includeTime: reminder.includeTime ?? false,
                readOnly: isUpcoming,
                onReadChanged: (isRead) =>
                    onReadChanged?.call(reminder, isRead),
                onDelete: () => onDelete?.call(reminder),
                onAction: (path) => onAction?.call(reminder, path),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Node?> _getNodeFromDocument(
    Future<Either<FlowyError, DocumentDataPB>> documentFuture,
    String blockId,
  ) async {
    final document = (await documentFuture).fold(
      (l) => null,
      (document) => document,
    );

    if (document == null) {
      return null;
    }

    final blockOrFailure = await DocumentService().getBlockFromDocument(
      document: document,
      blockId: blockId,
    );

    return blockOrFailure.fold(
      (_) => null,
      (block) => block.toNode(meta: MetaPB()),
    );
  }

  Future<int?> _getPathFromDocument(
    Future<Either<FlowyError, DocumentDataPB>> documentFuture,
    String blockId,
  ) async {
    final document = (await documentFuture).fold(
      (l) => null,
      (document) => document,
    );

    if (document == null) {
      return null;
    }

    final rootNode = document.toDocument()?.root;
    if (rootNode == null) {
      return null;
    }

    return _searchById(rootNode, blockId)?.path.first;
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

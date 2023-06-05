import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'dart:typed_data';

import 'package:appflowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:dartz/dartz.dart';

typedef OnGroupError = void Function(FlowyError);

abstract class GroupControllerDelegate {
  void removeRow(final GroupPB group, final String rowId);
  void insertRow(final GroupPB group, final RowPB row, final int? index);
  void updateRow(final GroupPB group, final RowPB row);
  void addNewRow(final GroupPB group, final RowPB row, final int? index);
}

class GroupController {
  final GroupPB group;
  final SingleGroupListener _listener;
  final GroupControllerDelegate delegate;

  GroupController({
    required final String viewId,
    required this.group,
    required this.delegate,
  }) : _listener = SingleGroupListener(group);

  RowPB? rowAtIndex(final int index) {
    if (index < group.rows.length) {
      return group.rows[index];
    } else {
      return null;
    }
  }

  RowPB? lastRow() {
    if (group.rows.isEmpty) return null;
    return group.rows.last;
  }

  void startListening() {
    _listener.start(
      onGroupChanged: (final result) {
        result.fold(
          (final GroupRowsNotificationPB changeset) {
            for (final deletedRow in changeset.deletedRows) {
              group.rows.removeWhere((final rowPB) => rowPB.id == deletedRow);
              delegate.removeRow(group, deletedRow);
            }

            for (final insertedRow in changeset.insertedRows) {
              final index = insertedRow.hasIndex() ? insertedRow.index : null;
              if (insertedRow.hasIndex() &&
                  group.rows.length > insertedRow.index) {
                group.rows.insert(insertedRow.index, insertedRow.row);
              } else {
                group.rows.add(insertedRow.row);
              }

              if (insertedRow.isNew) {
                delegate.addNewRow(group, insertedRow.row, index);
              } else {
                delegate.insertRow(group, insertedRow.row, index);
              }
            }

            for (final updatedRow in changeset.updatedRows) {
              final index = group.rows.indexWhere(
                (final rowPB) => rowPB.id == updatedRow.id,
              );

              if (index != -1) {
                group.rows[index] = updatedRow;
                delegate.updateRow(group, updatedRow);
              }
            }
          },
          (final err) => Log.error(err),
        );
      },
    );
  }

  Future<void> dispose() async {
    _listener.stop();
  }
}

typedef UpdateGroupNotifiedValue = Either<GroupRowsNotificationPB, FlowyError>;

class SingleGroupListener {
  final GroupPB group;
  PublishNotifier<UpdateGroupNotifiedValue>? _groupNotifier = PublishNotifier();
  DatabaseNotificationListener? _listener;
  SingleGroupListener(this.group);

  void start({
    required final void Function(UpdateGroupNotifiedValue) onGroupChanged,
  }) {
    _groupNotifier?.addPublishListener(onGroupChanged);
    _listener = DatabaseNotificationListener(
      objectId: group.groupId,
      handler: _handler,
    );
  }

  void _handler(
    final DatabaseNotification ty,
    final Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateGroupRow:
        result.fold(
          (final payload) => _groupNotifier?.value =
              left(GroupRowsNotificationPB.fromBuffer(payload)),
          (final error) => _groupNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _groupNotifier?.dispose();
    _groupNotifier = null;
  }
}

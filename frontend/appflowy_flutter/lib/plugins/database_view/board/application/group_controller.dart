import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'dart:typed_data';

import 'package:appflowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:dartz/dartz.dart';

typedef OnGroupError = void Function(FlowyError);

abstract class GroupControllerDelegate {
  void removeRow(GroupPB group, String rowId);
  void insertRow(GroupPB group, RowPB row, int? index);
  void updateRow(GroupPB group, RowPB row);
  void addNewRow(GroupPB group, RowPB row, int? index);
}

class GroupController {
  final GroupPB group;
  final SingleGroupListener _listener;
  final GroupControllerDelegate delegate;

  GroupController({
    required String viewId,
    required this.group,
    required this.delegate,
  }) : _listener = SingleGroupListener(group);

  RowPB? rowAtIndex(int index) {
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
    _listener.start(onGroupChanged: (result) {
      result.fold(
        (GroupRowsNotificationPB changeset) {
          for (final deletedRow in changeset.deletedRows) {
            group.rows.removeWhere((rowPB) => rowPB.id == deletedRow);
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
              (rowPB) => rowPB.id == updatedRow.id,
            );

            if (index != -1) {
              group.rows[index] = updatedRow;
              delegate.updateRow(group, updatedRow);
            }
          }
        },
        (err) => Log.error(err),
      );
    });
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
    required void Function(UpdateGroupNotifiedValue) onGroupChanged,
  }) {
    _groupNotifier?.addPublishListener(onGroupChanged);
    _listener = DatabaseNotificationListener(
      objectId: group.groupId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateGroupRow:
        result.fold(
          (payload) => _groupNotifier?.value =
              left(GroupRowsNotificationPB.fromBuffer(payload)),
          (error) => _groupNotifier?.value = right(error),
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

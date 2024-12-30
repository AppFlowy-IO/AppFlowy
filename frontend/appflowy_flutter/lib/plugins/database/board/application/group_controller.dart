import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:protobuf/protobuf.dart';

abstract class GroupControllerDelegate {
  bool hasGroup(String groupId);
  void removeRow(GroupPB group, RowId rowId);
  void insertRow(GroupPB group, RowMetaPB row, int? index);
  void updateRow(GroupPB group, RowMetaPB row);
  void addNewRow(GroupPB group, RowMetaPB row, int? index);
}

class GroupController {
  GroupController({
    required this.group,
    required this.delegate,
    required this.onGroupChanged,
  }) : _listener = SingleGroupListener(group);

  GroupPB group;
  final SingleGroupListener _listener;
  final GroupControllerDelegate delegate;
  final void Function(GroupPB group) onGroupChanged;

  RowMetaPB? rowAtIndex(int index) => group.rows.elementAtOrNull(index);

  RowMetaPB? firstRow() => group.rows.firstOrNull;

  RowMetaPB? lastRow() => group.rows.lastOrNull;

  void startListening() {
    _listener.start(
      onGroupChanged: (result) {
        result.fold(
          (GroupRowsNotificationPB changeset) {
            final newItems = [...group.rows];
            final isGroupExist = delegate.hasGroup(group.groupId);
            for (final deletedRow in changeset.deletedRows) {
              newItems.removeWhere((rowPB) => rowPB.id == deletedRow);
              if (isGroupExist) {
                delegate.removeRow(group, deletedRow);
              }
            }

            for (final insertedRow in changeset.insertedRows) {
              if (newItems.any((rowPB) => rowPB.id == insertedRow.rowMeta.id)) {
                continue;
              }

              final index = insertedRow.hasIndex() ? insertedRow.index : null;
              if (insertedRow.hasIndex() &&
                  newItems.length > insertedRow.index) {
                newItems.insert(insertedRow.index, insertedRow.rowMeta);
              } else {
                newItems.add(insertedRow.rowMeta);
              }

              if (isGroupExist) {
                if (insertedRow.isNew) {
                  delegate.addNewRow(group, insertedRow.rowMeta, index);
                } else {
                  delegate.insertRow(group, insertedRow.rowMeta, index);
                }
              }
            }

            for (final updatedRow in changeset.updatedRows) {
              final index = newItems.indexWhere(
                (rowPB) => rowPB.id == updatedRow.id,
              );

              if (index != -1) {
                newItems[index] = updatedRow;
                if (isGroupExist) {
                  delegate.updateRow(group, updatedRow);
                }
              }
            }

            group = group.rebuild((group) {
              group.rows.clear();
              group.rows.addAll(newItems);
            });
            group.freeze();
            Log.debug(
              "Build GroupPB:${group.groupId}: items: ${group.rows.length}",
            );
            onGroupChanged(group);
          },
          (err) => Log.error(err),
        );
      },
    );
  }

  Future<void> dispose() async {
    await _listener.stop();
  }
}

typedef UpdateGroupNotifiedValue
    = FlowyResult<GroupRowsNotificationPB, FlowyError>;

class SingleGroupListener {
  SingleGroupListener(this.group);

  final GroupPB group;

  PublishNotifier<UpdateGroupNotifiedValue>? _groupNotifier = PublishNotifier();
  DatabaseNotificationListener? _listener;

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
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateGroupRow:
        result.fold(
          (payload) => _groupNotifier?.value =
              FlowyResult.success(GroupRowsNotificationPB.fromBuffer(payload)),
          (error) => _groupNotifier?.value = FlowyResult.failure(error),
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

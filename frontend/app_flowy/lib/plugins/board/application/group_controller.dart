import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';

import 'group_listener.dart';

typedef OnGroupError = void Function(FlowyError);

abstract class GroupControllerDelegate {
  void removeRow(GroupPB group, String rowId);
  void insertRow(GroupPB group, RowPB row, int? index);
  void updateRow(GroupPB group, RowPB row);
}

class GroupController {
  final GroupPB group;
  final GroupListener _listener;
  final GroupControllerDelegate delegate;

  GroupController({
    required String gridId,
    required this.group,
    required this.delegate,
  }) : _listener = GroupListener(group);

  RowPB? rowAtIndex(int index) {
    if (index < group.rows.length) {
      return group.rows[index];
    } else {
      return null;
    }
  }

  void startListening() {
    _listener.start(onGroupChanged: (result) {
      result.fold(
        (GroupChangesetPB changeset) {
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

            delegate.insertRow(
              group,
              insertedRow.row,
              index,
            );
          }

          for (final updatedRow in changeset.updatedRows) {
            final index = group.rows.indexWhere(
              (rowPB) => rowPB.id == updatedRow.id,
            );

            if (index != -1) {
              group.rows[index] = updatedRow;
            }

            delegate.updateRow(group, updatedRow);
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

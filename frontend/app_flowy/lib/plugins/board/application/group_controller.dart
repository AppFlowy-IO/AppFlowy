import 'package:app_flowy/plugins/grid/application/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';

import 'group_listener.dart';

typedef OnGroupError = void Function(FlowyError);

abstract class GroupControllerDelegate {
  void removeRow(String groupId, String rowId);
  void insertRow(String groupId, RowPB row, int? index);
  void updateRow(String groupId, RowPB row);
}

class GroupController {
  final GroupPB group;
  final GroupListener _listener;
  final MoveRowFFIService _rowService;
  final GroupControllerDelegate delegate;
  OnGroupError? _onError;

  GroupController({
    required String gridId,
    required this.group,
    required this.delegate,
  })  : _rowService = MoveRowFFIService(gridId: gridId),
        _listener = GroupListener(group);

  Future<void> moveRow(int fromIndex, int toIndex) async {
    if (fromIndex < group.rows.length && toIndex < group.rows.length) {
      final fromRow = group.rows[fromIndex];
      final toRow = group.rows[toIndex];

      final result = await _rowService.moveRow(
        rowId: fromRow.id,
        fromIndex: fromIndex,
        toIndex: toIndex,
        upperRowId: toRow.id,
        layout: GridLayout.Board,
      );

      result.fold((l) => null, (r) => _onError?.call(r));
    }
  }

  void startListening({OnGroupError? onError}) {
    _onError = onError;
    _listener.start(onGroupChanged: (result) {
      result.fold(
        (GroupRowsChangesetPB changeset) {
          for (final insertedRow in changeset.insertedRows) {
            final index = insertedRow.hasIndex() ? insertedRow.index : null;
            delegate.insertRow(
              group.groupId,
              insertedRow.row,
              index,
            );
          }

          for (final deletedRow in changeset.deletedRows) {
            delegate.removeRow(group.groupId, deletedRow);
          }

          for (final updatedRow in changeset.updatedRows) {
            delegate.updateRow(group.groupId, updatedRow);
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

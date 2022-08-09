import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'row_service.freezed.dart';

typedef RowUpdateCallback = void Function();

abstract class GridRowCacheFieldNotifier {
  UnmodifiableListView<GridFieldPB> get fields;
  void onFieldsChanged(VoidCallback callback);
  void onFieldChanged(void Function(GridFieldPB) callback);
  void dispose();
}

/// Cache the rows in memory
/// Insert / delete / update row
///
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information.

class GridRowCache {
  final String gridId;
  final GridBlockPB block;

  /// _rows containers the current block's rows
  /// Use List to reverse the order of the GridRow.
  List<GridRowInfo> _rowInfos = [];

  /// Use Map for faster access the raw row data.
  final HashMap<String, GridRowPB> _rowByRowId;

  final GridCellCache _cellCache;
  final GridRowCacheFieldNotifier _fieldNotifier;
  final _GridRowChangesetNotifier _rowChangeReasonNotifier;

  UnmodifiableListView<GridRowInfo> get rows => UnmodifiableListView(_rowInfos);
  GridCellCache get cellCache => _cellCache;

  GridRowCache({
    required this.gridId,
    required this.block,
    required GridRowCacheFieldNotifier notifier,
  })  : _cellCache = GridCellCache(gridId: gridId),
        _rowByRowId = HashMap(),
        _rowChangeReasonNotifier = _GridRowChangesetNotifier(),
        _fieldNotifier = notifier {
    //
    notifier.onFieldsChanged(() => _rowChangeReasonNotifier
        .receive(const GridRowChangeReason.fieldDidChange()));
    notifier.onFieldChanged((field) => _cellCache.remove(field.id));
    _rowInfos = block.rows
        .map((rowInfo) => buildGridRow(rowInfo.id, rowInfo.height.toDouble()))
        .toList();
  }

  Future<void> dispose() async {
    _fieldNotifier.dispose();
    _rowChangeReasonNotifier.dispose();
    await _cellCache.dispose();
  }

  void applyChangesets(List<GridBlockChangesetPB> changesets) {
    for (final changeset in changesets) {
      _deleteRows(changeset.deletedRows);
      _insertRows(changeset.insertedRows);
      _updateRows(changeset.updatedRows);
      _hideRows(changeset.hideRows);
      _showRows(changeset.visibleRows);
    }
  }

  void _deleteRows(List<String> deletedRows) {
    if (deletedRows.isEmpty) {
      return;
    }

    final List<GridRowInfo> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, String> deletedRowByRowId = {
      for (var rowId in deletedRows) rowId: rowId
    };

    _rowInfos.asMap().forEach((index, row) {
      if (deletedRowByRowId[row.id] == null) {
        newRows.add(row);
      } else {
        _rowByRowId.remove(row.id);
        deletedIndex.add(DeletedIndex(index: index, row: row));
      }
    });
    _rowInfos = newRows;
    _rowChangeReasonNotifier.receive(GridRowChangeReason.delete(deletedIndex));
  }

  void _insertRows(List<InsertedRowPB> insertRows) {
    if (insertRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    for (final insertRow in insertRows) {
      final insertIndex = InsertedIndex(
        index: insertRow.index,
        rowId: insertRow.rowId,
      );
      insertIndexs.add(insertIndex);
      _rowInfos.insert(insertRow.index,
          (buildGridRow(insertRow.rowId, insertRow.height.toDouble())));
    }

    _rowChangeReasonNotifier.receive(GridRowChangeReason.insert(insertIndexs));
  }

  void _updateRows(List<UpdatedRowPB> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
    for (final updatedRow in updatedRows) {
      final rowId = updatedRow.rowId;
      final index = _rowInfos.indexWhere((row) => row.id == rowId);
      if (index != -1) {
        _rowByRowId[rowId] = updatedRow.row;

        _rowInfos.removeAt(index);
        _rowInfos.insert(
            index, buildGridRow(rowId, updatedRow.row.height.toDouble()));
        updatedIndexs[rowId] = UpdatedIndex(index: index, rowId: rowId);
      }
    }

    _rowChangeReasonNotifier.receive(GridRowChangeReason.update(updatedIndexs));
  }

  void _hideRows(List<String> hideRows) {}

  void _showRows(List<String> visibleRows) {}

  void onRowsChanged(
    void Function(GridRowChangeReason) onRowChanged,
  ) {
    _rowChangeReasonNotifier.addListener(() {
      onRowChanged(_rowChangeReasonNotifier.reason);
    });
  }

  RowUpdateCallback addListener({
    required String rowId,
    void Function(GridCellMap, GridRowChangeReason)? onCellUpdated,
    bool Function()? listenWhen,
  }) {
    listenrHandler() async {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      notifyUpdate() {
        if (onCellUpdated != null) {
          final row = _rowByRowId[rowId];
          if (row != null) {
            final GridCellMap cellDataMap = _makeGridCells(rowId, row);
            onCellUpdated(cellDataMap, _rowChangeReasonNotifier.reason);
          }
        }
      }

      _rowChangeReasonNotifier.reason.whenOrNull(
        update: (indexs) {
          if (indexs[rowId] != null) notifyUpdate();
        },
        fieldDidChange: () => notifyUpdate(),
      );
    }

    _rowChangeReasonNotifier.addListener(listenrHandler);
    return listenrHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _rowChangeReasonNotifier.removeListener(callback);
  }

  GridCellMap loadGridCells(String rowId) {
    final GridRowPB? data = _rowByRowId[rowId];
    if (data == null) {
      _loadRow(rowId);
    }
    return _makeGridCells(rowId, data);
  }

  Future<void> _loadRow(String rowId) async {
    final payload = GridRowIdPB.create()
      ..gridId = gridId
      ..blockId = block.id
      ..rowId = rowId;

    final result = await GridEventGetRow(payload).send();
    result.fold(
      (optionRow) => _refreshRow(optionRow),
      (err) => Log.error(err),
    );
  }

  GridCellMap _makeGridCells(String rowId, GridRowPB? row) {
    var cellDataMap = GridCellMap.new();
    for (final field in _fieldNotifier.fields) {
      if (field.visibility) {
        cellDataMap[field.id] = GridCellIdentifier(
          rowId: rowId,
          gridId: gridId,
          field: field,
        );
      }
    }
    return cellDataMap;
  }

  void _refreshRow(OptionalRowPB optionRow) {
    if (!optionRow.hasRow()) {
      return;
    }
    final updatedRow = optionRow.row;
    updatedRow.freeze();

    _rowByRowId[updatedRow.id] = updatedRow;
    final index =
        _rowInfos.indexWhere((gridRow) => gridRow.id == updatedRow.id);
    if (index != -1) {
      // update the corresponding row in _rows if they are not the same
      if (_rowInfos[index].rawRow != updatedRow) {
        final row = _rowInfos.removeAt(index).copyWith(rawRow: updatedRow);
        _rowInfos.insert(index, row);

        // Calculate the update index
        final UpdatedIndexs updatedIndexs = UpdatedIndexs();
        updatedIndexs[row.id] = UpdatedIndex(index: index, rowId: row.id);

        //
        _rowChangeReasonNotifier
            .receive(GridRowChangeReason.update(updatedIndexs));
      }
    }
  }

  GridRowInfo buildGridRow(String rowId, double rowHeight) {
    return GridRowInfo(
      gridId: gridId,
      blockId: block.id,
      fields: _fieldNotifier.fields,
      id: rowId,
      height: rowHeight,
    );
  }
}

class _GridRowChangesetNotifier extends ChangeNotifier {
  GridRowChangeReason reason = const InitialListState();

  _GridRowChangesetNotifier();

  void receive(GridRowChangeReason newReason) {
    reason = newReason;
    reason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      fieldDidChange: (_) => notifyListeners(),
      initial: (_) {},
    );
  }
}

class RowService {
  final String gridId;
  final String blockId;
  final String rowId;

  RowService(
      {required this.gridId, required this.blockId, required this.rowId});

  Future<Either<GridRowPB, FlowyError>> createRow() {
    CreateRowPayloadPB payload = CreateRowPayloadPB.create()
      ..gridId = gridId
      ..startRowId = rowId;

    return GridEventCreateRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveRow(
      String rowId, int fromIndex, int toIndex) {
    final payload = MoveItemPayloadPB.create()
      ..gridId = gridId
      ..itemId = rowId
      ..ty = MoveItemTypePB.MoveRow
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return GridEventMoveItem(payload).send();
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow() {
    final payload = GridRowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow() {
    final payload = GridRowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow() {
    final payload = GridRowIdPB.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}

@freezed
class GridRowInfo with _$GridRowInfo {
  const factory GridRowInfo({
    required String gridId,
    required String blockId,
    required String id,
    required UnmodifiableListView<GridFieldPB> fields,
    required double height,
    GridRowPB? rawRow,
  }) = _GridRowInfo;
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
typedef UpdatedIndexs = LinkedHashMap<String, UpdatedIndex>;

@freezed
class GridRowChangeReason with _$GridRowChangeReason {
  const factory GridRowChangeReason.insert(InsertedIndexs items) = _Insert;
  const factory GridRowChangeReason.delete(DeletedIndexs items) = _Delete;
  const factory GridRowChangeReason.update(UpdatedIndexs indexs) = _Update;
  const factory GridRowChangeReason.fieldDidChange() = _FieldDidChange;
  const factory GridRowChangeReason.initial() = InitialListState;
}

class InsertedIndex {
  final int index;
  final String rowId;
  InsertedIndex({
    required this.index,
    required this.rowId,
  });
}

class DeletedIndex {
  final int index;
  final GridRowInfo row;
  DeletedIndex({
    required this.index,
    required this.row,
  });
}

class UpdatedIndex {
  final int index;
  final String rowId;
  UpdatedIndex({
    required this.index,
    required this.rowId,
  });
}

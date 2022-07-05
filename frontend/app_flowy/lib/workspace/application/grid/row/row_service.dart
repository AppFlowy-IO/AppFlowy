import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
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

abstract class GridRowCacheDelegate with GridCellCacheDelegate {
  UnmodifiableListView<Field> get fields;
  void onFieldsChanged(void Function() callback);
  void dispose();
}

class GridRowCacheService {
  final String gridId;
  final GridBlock block;
  final _Notifier _notifier;
  List<GridRow> _rows = [];
  final HashMap<String, Row> _rowByRowId;
  final GridRowCacheDelegate _delegate;
  final GridCellCacheService _cellCache;

  List<GridRow> get rows => _rows;
  GridCellCacheService get cellCache => _cellCache;

  GridRowCacheService({
    required this.gridId,
    required this.block,
    required GridRowCacheDelegate delegate,
  })  : _cellCache = GridCellCacheService(gridId: gridId, delegate: delegate),
        _rowByRowId = HashMap(),
        _notifier = _Notifier(),
        _delegate = delegate {
    //
    delegate.onFieldsChanged(() => _notifier.receive(const GridRowChangeReason.fieldDidChange()));
    _rows = block.rowInfos.map((rowInfo) => buildGridRow(rowInfo.rowId, rowInfo.height.toDouble())).toList();
  }

  Future<void> dispose() async {
    _delegate.dispose();
    _notifier.dispose();
    await _cellCache.dispose();
  }

  void applyChangesets(List<GridBlockChangeset> changesets) {
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

    final List<GridRow> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, String> deletedRowByRowId = {for (var rowId in deletedRows) rowId: rowId};

    _rows.asMap().forEach((index, row) {
      if (deletedRowByRowId[row.rowId] == null) {
        newRows.add(row);
      } else {
        deletedIndex.add(DeletedIndex(index: index, row: row));
      }
    });
    _rows = newRows;
    _notifier.receive(GridRowChangeReason.delete(deletedIndex));
  }

  void _insertRows(List<InsertedRow> insertRows) {
    if (insertRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    final List<GridRow> newRows = _rows;
    for (final insertRow in insertRows) {
      final insertIndex = InsertedIndex(
        index: insertRow.index,
        rowId: insertRow.rowId,
      );
      insertIndexs.add(insertIndex);
      newRows.insert(insertRow.index, (buildGridRow(insertRow.rowId, insertRow.height.toDouble())));
    }

    _notifier.receive(GridRowChangeReason.insert(insertIndexs));
  }

  void _updateRows(List<UpdatedRow> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
    final List<GridRow> newRows = _rows;
    for (final updatedRow in updatedRows) {
      final rowId = updatedRow.rowId;
      final index = newRows.indexWhere((row) => row.rowId == rowId);
      if (index != -1) {
        _rowByRowId[rowId] = updatedRow.row;

        newRows.removeAt(index);
        newRows.insert(index, buildGridRow(rowId, updatedRow.row.height.toDouble()));
        updatedIndexs[rowId] = UpdatedIndex(index: index, rowId: rowId);
      }
    }

    _notifier.receive(GridRowChangeReason.update(updatedIndexs));
  }

  void _hideRows(List<String> hideRows) {}

  void _showRows(List<String> visibleRows) {}

  void onRowsChanged(
    void Function(GridRowChangeReason) onRowChanged,
  ) {
    _notifier.addListener(() {
      onRowChanged(_notifier._reason);
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
            onCellUpdated(cellDataMap, _notifier._reason);
          }
        }
      }

      _notifier._reason.whenOrNull(
        update: (indexs) {
          if (indexs[rowId] != null) notifyUpdate();
        },
        fieldDidChange: () => notifyUpdate(),
      );
    }

    _notifier.addListener(listenrHandler);
    return listenrHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _notifier.removeListener(callback);
  }

  GridCellMap loadGridCells(String rowId) {
    final Row? data = _rowByRowId[rowId];
    if (data == null) {
      _loadRow(rowId);
    }
    return _makeGridCells(rowId, data);
  }

  Future<void> _loadRow(String rowId) async {
    final payload = GridRowIdPayload.create()
      ..gridId = gridId
      ..blockId = block.id
      ..rowId = rowId;

    final result = await GridEventGetRow(payload).send();
    result.fold(
      (optionRow) => _refreshRow(optionRow),
      (err) => Log.error(err),
    );
  }

  GridCellMap _makeGridCells(String rowId, Row? row) {
    var cellDataMap = GridCellMap.new();
    for (final field in _delegate.fields) {
      if (field.visibility) {
        cellDataMap[field.id] = GridCell(
          rowId: rowId,
          gridId: gridId,
          field: field,
        );
      }
    }
    return cellDataMap;
  }

  void _refreshRow(OptionalRow optionRow) {
    if (!optionRow.hasRow()) {
      return;
    }
    final updatedRow = optionRow.row;
    updatedRow.freeze();

    _rowByRowId[updatedRow.id] = updatedRow;
    final index = _rows.indexWhere((gridRow) => gridRow.rowId == updatedRow.id);
    if (index != -1) {
      // update the corresponding row in _rows if they are not the same
      if (_rows[index].data != updatedRow) {
        final row = _rows.removeAt(index).copyWith(data: updatedRow);
        _rows.insert(index, row);

        // Calculate the update index
        final UpdatedIndexs updatedIndexs = UpdatedIndexs();
        updatedIndexs[row.rowId] = UpdatedIndex(index: index, rowId: row.rowId);

        //
        _notifier.receive(GridRowChangeReason.update(updatedIndexs));
      }
    }
  }

  GridRow buildGridRow(String rowId, double rowHeight) {
    return GridRow(
      gridId: gridId,
      blockId: block.id,
      fields: _delegate.fields,
      rowId: rowId,
      height: rowHeight,
    );
  }
}

class _Notifier extends ChangeNotifier {
  GridRowChangeReason _reason = const InitialListState();

  _Notifier();

  void receive(GridRowChangeReason reason) {
    _reason = reason;
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

  RowService({required this.gridId, required this.blockId, required this.rowId});

  Future<Either<Row, FlowyError>> createRow() {
    CreateRowPayload payload = CreateRowPayload.create()
      ..gridId = gridId
      ..startRowId = rowId;

    return GridEventCreateRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveRow(String rowId, int fromIndex, int toIndex) {
    final payload = MoveItemPayload.create()
      ..gridId = gridId
      ..itemId = rowId
      ..ty = MoveItemType.MoveRow
      ..fromIndex = fromIndex
      ..toIndex = toIndex;

    return GridEventMoveItem(payload).send();
  }

  Future<Either<OptionalRow, FlowyError>> getRow() {
    final payload = GridRowIdPayload.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow() {
    final payload = GridRowIdPayload.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow() {
    final payload = GridRowIdPayload.create()
      ..gridId = gridId
      ..blockId = blockId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}

@freezed
class GridRow with _$GridRow {
  const factory GridRow({
    required String gridId,
    required String blockId,
    required String rowId,
    required UnmodifiableListView<Field> fields,
    required double height,
    Row? data,
  }) = _GridRow;
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
  final GridRow row;
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

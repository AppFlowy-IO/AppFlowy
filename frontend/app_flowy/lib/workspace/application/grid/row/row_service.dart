import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/application/grid/grid_listener.dart';
part 'row_service.freezed.dart';

typedef RowUpdateCallback = void Function();
typedef FieldDidUpdateCallback = void Function();
typedef CellDataMap = LinkedHashMap<String, GridCell>;

abstract class GridRowDataDelegate {
  UnmodifiableListView<Field> get fields;
  GridRow buildGridRow(RowOrder rowOrder);
  CellDataMap buildCellDataMap(String rowId, Row? rowData);
  void onFieldChanged(FieldDidUpdateCallback callback);
}

class GridRowCache {
  final String gridId;
  final RowsNotifier _rowNotifier;
  final GridRowListener _rowsListener;
  final GridRowDataDelegate _dataDelegate;

  List<GridRow> get clonedRows => _rowNotifier.clonedRows;

  GridRowCache({required this.gridId, required GridRowDataDelegate dataDelegate})
      : _rowNotifier = RowsNotifier(rowBuilder: dataDelegate.buildGridRow),
        _rowsListener = GridRowListener(gridId: gridId),
        _dataDelegate = dataDelegate {
    //
    dataDelegate.onFieldChanged(() => _rowNotifier.fieldDidChange());

    // listen on the row update
    _rowsListener.rowsUpdateNotifier.addPublishListener((result) {
      result.fold(
        (changesets) {
          for (final changeset in changesets) {
            _rowNotifier.deleteRows(changeset.deletedRows);
            _rowNotifier.insertRows(changeset.insertedRows);
            _rowNotifier.updateRows(changeset.updatedRows);
          }
        },
        (err) => Log.error(err),
      );
    });
    _rowsListener.start();
  }

  Future<void> dispose() async {
    await _rowsListener.stop();
    _rowNotifier.dispose();
  }

  void addListener({
    void Function(List<GridRow>, GridRowChangeReason)? onChanged,
    bool Function()? listenWhen,
  }) {
    _rowNotifier.addListener(() {
      if (onChanged == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      onChanged(clonedRows, _rowNotifier._changeReason);
    });
  }

  RowUpdateCallback addRowListener({
    required String rowId,
    void Function(CellDataMap)? onUpdated,
    bool Function()? listenWhen,
  }) {
    listenrHandler() {
      if (onUpdated == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      notify() {
        final row = _rowNotifier.rowDataWithId(rowId);
        if (row != null) {
          final cellDataMap = _dataDelegate.buildCellDataMap(rowId, row);
          onUpdated(cellDataMap);
        }
      }

      _rowNotifier._changeReason.whenOrNull(
        update: (indexs) {
          if (indexs[rowId] != null) {
            notify();
          }
        },
        fieldDidChange: () => notify(),
      );
    }

    _rowNotifier.addListener(listenrHandler);
    return listenrHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _rowNotifier.removeListener(callback);
  }

  CellDataMap loadCellData(String rowId) {
    final Row? data = _rowNotifier.rowDataWithId(rowId);
    if (data == null) {
      final payload = RowIdentifierPayload.create()
        ..gridId = gridId
        ..rowId = rowId;

      GridEventGetRow(payload).send().then((result) {
        result.fold(
          (rowData) => _rowNotifier.rowData = rowData,
          (err) => Log.error(err),
        );
      });
    }

    return _dataDelegate.buildCellDataMap(rowId, data);
  }

  void updateWithBlock(List<GridBlockOrder> blocks) {
    final rowOrders = blocks.expand((block) => block.rowOrders).toList();
    _rowNotifier.reset(rowOrders);
  }
}

class RowsNotifier extends ChangeNotifier {
  List<GridRow> _rows = [];
  HashMap<String, Row> _rowDataMap = HashMap();
  GridRowChangeReason _changeReason = const InitialListState();
  final GridRow Function(RowOrder) rowBuilder;

  RowsNotifier({
    required this.rowBuilder,
  });

  void reset(List<RowOrder> rowOrders) {
    _rowDataMap = HashMap();
    final rows = rowOrders.map((rowOrder) => rowBuilder(rowOrder)).toList();
    _update(rows, const GridRowChangeReason.initial());
  }

  void deleteRows(List<RowOrder> deletedRows) {
    if (deletedRows.isEmpty) {
      return;
    }

    final List<GridRow> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, RowOrder> deletedRowMap = {for (var e in deletedRows) e.rowId: e};

    _rows.asMap().forEach((index, row) {
      if (deletedRowMap[row.rowId] == null) {
        newRows.add(row);
      } else {
        deletedIndex.add(DeletedIndex(index: index, row: row));
      }
    });

    _update(newRows, GridRowChangeReason.delete(deletedIndex));
  }

  void insertRows(List<IndexRowOrder> createdRows) {
    if (createdRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    final List<GridRow> newRows = clonedRows;
    for (final createdRow in createdRows) {
      final insertIndex = InsertedIndex(
        index: createdRow.index,
        rowId: createdRow.rowOrder.rowId,
      );
      insertIndexs.add(insertIndex);
      newRows.insert(createdRow.index, (rowBuilder(createdRow.rowOrder)));
    }
    _update(newRows, GridRowChangeReason.insert(insertIndexs));
  }

  void updateRows(List<RowOrder> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
    final List<GridRow> newRows = clonedRows;
    for (final rowOrder in updatedRows) {
      final index = newRows.indexWhere((row) => row.rowId == rowOrder.rowId);
      if (index != -1) {
        // Remove the old row data, the data will be filled if the loadRow method gets called.
        _rowDataMap.remove(rowOrder.rowId);

        newRows.removeAt(index);
        newRows.insert(index, rowBuilder(rowOrder));
        updatedIndexs[rowOrder.rowId] = UpdatedIndex(index: index, rowId: rowOrder.rowId);
      }
    }

    _update(newRows, GridRowChangeReason.update(updatedIndexs));
  }

  void fieldDidChange() {
    _update(_rows, const GridRowChangeReason.fieldDidChange());
  }

  void _update(List<GridRow> rows, GridRowChangeReason reason) {
    _rows = rows;
    _changeReason = reason;

    _changeReason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      fieldDidChange: (_) => notifyListeners(),
      initial: (_) {},
    );
  }

  set rowData(Row rowData) {
    rowData.freeze();

    _rowDataMap[rowData.id] = rowData;
    final index = _rows.indexWhere((row) => row.rowId == rowData.id);
    if (index != -1) {
      // update the corresponding row in _rows if they are not the same
      if (_rows[index].data != rowData) {
        final row = _rows.removeAt(index).copyWith(data: rowData);
        _rows.insert(index, row);

        // Calculate the update index
        final UpdatedIndexs updatedIndexs = UpdatedIndexs();
        updatedIndexs[row.rowId] = UpdatedIndex(index: index, rowId: row.rowId);
        _changeReason = GridRowChangeReason.update(updatedIndexs);

        //
        notifyListeners();
      }
    }
  }

  Row? rowDataWithId(String rowId) {
    return _rowDataMap[rowId];
  }

  List<GridRow> get clonedRows => [..._rows];
}

class RowService {
  final String gridId;
  final String rowId;

  RowService({required this.gridId, required this.rowId});

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

  Future<Either<Row, FlowyError>> getRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventGetRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> deleteRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDeleteRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> duplicateRow() {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    return GridEventDuplicateRow(payload).send();
  }
}

@freezed
class GridRow with _$GridRow {
  const factory GridRow({
    required String gridId,
    required String rowId,
    required List<Field> fields,
    required double height,
    Row? data,
  }) = _GridRow;
}

@freezed
class GridCell with _$GridCell {
  const factory GridCell({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _GridCell;

  ValueKey key() {
    return ValueKey(rowId + (cell?.fieldId ?? ""));
  }
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

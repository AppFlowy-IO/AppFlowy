import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/field.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'row_service.freezed.dart';

typedef RowUpdateCallback = void Function();
typedef FieldDidUpdateCallback = void Function();

abstract class GridRowFieldDelegate {
  UnmodifiableListView<Field> get fields;
  void onFieldChanged(FieldDidUpdateCallback callback);
}

class GridRowCache {
  final String gridId;
  final RowsNotifier _rowsNotifier;
  final GridRowFieldDelegate _fieldDelegate;
  List<GridRow> get clonedRows => _rowsNotifier.clonedRows;

  GridRowCache({required this.gridId, required GridRowFieldDelegate fieldDelegate})
      : _rowsNotifier = RowsNotifier(
          rowBuilder: (rowOrder) {
            return GridRow(
              gridId: gridId,
              fields: fieldDelegate.fields,
              rowId: rowOrder.rowId,
              height: rowOrder.height.toDouble(),
            );
          },
        ),
        _fieldDelegate = fieldDelegate {
    //
    fieldDelegate.onFieldChanged(() => _rowsNotifier.fieldDidChange());
  }

  Future<void> dispose() async {
    _rowsNotifier.dispose();
  }

  void applyChangesets(List<GridRowsChangeset> changesets) {
    for (final changeset in changesets) {
      _rowsNotifier.deleteRows(changeset.deletedRows);
      _rowsNotifier.insertRows(changeset.insertedRows);
      _rowsNotifier.updateRows(changeset.updatedRows);
    }
  }

  void addListener({
    void Function(List<GridRow>, GridRowChangeReason)? onChanged,
    bool Function()? listenWhen,
  }) {
    _rowsNotifier.addListener(() {
      if (onChanged == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      onChanged(clonedRows, _rowsNotifier._changeReason);
    });
  }

  RowUpdateCallback addRowListener({
    required String rowId,
    void Function(GridCellMap, GridRowChangeReason)? onUpdated,
    bool Function()? listenWhen,
  }) {
    listenrHandler() async {
      if (onUpdated == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      notify() {
        final row = _rowsNotifier.rowDataWithId(rowId);
        if (row != null) {
          final GridCellMap cellDataMap = _makeGridCells(rowId, row);
          onUpdated(cellDataMap, _rowsNotifier._changeReason);
        }
      }

      _rowsNotifier._changeReason.whenOrNull(
        update: (indexs) {
          if (indexs[rowId] != null) {
            notify();
          }
        },
        fieldDidChange: () => notify(),
      );
    }

    _rowsNotifier.addListener(listenrHandler);
    return listenrHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _rowsNotifier.removeListener(callback);
  }

  GridCellMap loadGridCells(String rowId) {
    final Row? data = _rowsNotifier.rowDataWithId(rowId);
    if (data == null) {
      _loadRow(rowId);
    }
    return _makeGridCells(rowId, data);
  }

  void initialRows(List<RowOrder> rowOrders) {
    _rowsNotifier.initialRows(rowOrders);
  }

  Future<void> _loadRow(String rowId) async {
    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    final result = await GridEventGetRow(payload).send();
    result.fold(
      (rowData) {
        if (rowData.hasRow()) {
          _rowsNotifier.rowData = rowData.row;
        }
      },
      (err) => Log.error(err),
    );
  }

  GridCellMap _makeGridCells(String rowId, Row? row) {
    var cellDataMap = GridCellMap.new();
    for (final field in _fieldDelegate.fields) {
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
}

class RowsNotifier extends ChangeNotifier {
  List<GridRow> _rows = [];
  HashMap<String, Row> _rowDataMap = HashMap();
  GridRowChangeReason _changeReason = const InitialListState();
  final GridRow Function(RowOrder) rowBuilder;

  RowsNotifier({
    required this.rowBuilder,
  });

  List<GridRow> get clonedRows => [..._rows];

  void initialRows(List<RowOrder> rowOrders) {
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

  void insertRows(List<IndexRowOrder> insertRows) {
    if (insertRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    final List<GridRow> newRows = clonedRows;
    for (final insertRow in insertRows) {
      final insertIndex = InsertedIndex(
        index: insertRow.index,
        rowId: insertRow.rowOrder.rowId,
      );
      insertIndexs.add(insertIndex);
      newRows.insert(insertRow.index, (rowBuilder(insertRow.rowOrder)));
    }
    _update(newRows, GridRowChangeReason.insert(insertIndexs));
  }

  void updateRows(List<UpdatedRowOrder> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
    final List<GridRow> newRows = clonedRows;
    for (final updatedRow in updatedRows) {
      final rowOrder = updatedRow.rowOrder;
      final index = newRows.indexWhere((row) => row.rowId == rowOrder.rowId);
      if (index != -1) {
        _rowDataMap[rowOrder.rowId] = updatedRow.row;

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

  Future<Either<OptionalRow, FlowyError>> getRow() {
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

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

class GridRowCache {
  final String gridId;
  final GridRowListener _rowsListener;
  late final _RowsNotifier _rowNotifier;
  UnmodifiableListView<Field> _fields = UnmodifiableListView([]);

  List<GridRow> get clonedRows => _rowNotifier.clonedRows;

  GridRowCache({required this.gridId}) : _rowsListener = GridRowListener(gridId: gridId) {
    _rowNotifier = _RowsNotifier(
      rowBuilder: (rowOrder) {
        return GridRow(
          gridId: gridId,
          fields: _fields,
          rowId: rowOrder.rowId,
          height: rowOrder.height.toDouble(),
        );
      },
    );

    _rowsListener.rowsUpdateNotifier.addPublishListener((result) {
      result.fold(
        (changesets) {
          for (final changeset in changesets) {
            _deleteRows(changeset.deletedRows);
            _insertRows(changeset.insertedRows);
            _updateRows(changeset.updatedRows);
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
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      if (onChanged != null) {
        onChanged(clonedRows, _rowNotifier._changeReason);
      }
    });
  }

  VoidCallback addRowListener({
    required String rowId,
    void Function(Row)? onUpdated,
    bool Function()? listenWhen,
  }) {
    listenrHandler() {
      if (onUpdated == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      _rowNotifier._changeReason.whenOrNull(update: (indexs) {
        final row = _rowNotifier.rowDataWithId(rowId);
        if (indexs[rowId] != null && row != null) {
          onUpdated(row);
        }
      });
    }

    _rowNotifier.addListener(listenrHandler);
    return listenrHandler;
  }

  void removeRowListener(VoidCallback callback) {
    _rowNotifier.removeListener(callback);
  }

  Option<Row> loadRow(String rowId) {
    final Row? data = _rowNotifier.rowDataWithId(rowId);
    if (data != null) {
      return Some(data);
    }

    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    GridEventGetRow(payload).send().then((result) {
      result.fold(
        (rowData) => _rowNotifier.rowData = rowData,
        (err) => Log.error(err),
      );
    });
    return none();
  }

  void updateWithBlock(List<GridBlockOrder> blocks, UnmodifiableListView<Field> fields) {
    _fields = fields;
    final rowOrders = blocks.expand((block) => block.rowOrders).toList();
    _rowNotifier.reset(rowOrders);
  }

  void _deleteRows(List<RowOrder> deletedRows) {
    _rowNotifier.deleteRows(deletedRows);
  }

  void _insertRows(List<IndexRowOrder> createdRows) {
    _rowNotifier.insertRows(createdRows);
  }

  void _updateRows(List<RowOrder> rowOrders) {
    _rowNotifier.updateRows(rowOrders);
  }
}

class _RowsNotifier extends ChangeNotifier {
  List<GridRow> _rows = [];
  HashMap<String, Row> _rowDataMap = HashMap();
  GridRowChangeReason _changeReason = const InitialListState();
  final GridRow Function(RowOrder) rowBuilder;

  _RowsNotifier({
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
    final Map<String, RowOrder> deletedRowMap = {for (var rowOrder in deletedRows) rowOrder.rowId: rowOrder};

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
    final List<GridRow> newRows = _rows;
    for (final createdRow in createdRows) {
      final rowOrder = createdRow.rowOrder;
      final insertIndex = InsertedIndex(index: createdRow.index, rowId: rowOrder.rowId);
      insertIndexs.add(insertIndex);
      newRows.insert(createdRow.index, (rowBuilder(rowOrder)));
    }
    _update(newRows, GridRowChangeReason.insert(insertIndexs));
  }

  void updateRows(List<RowOrder> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = UpdatedIndexs();
    final List<GridRow> newRows = _rows;
    for (final rowOrder in updatedRows) {
      final index = newRows.indexWhere((row) => row.rowId == rowOrder.rowId);
      if (index != -1) {
        newRows.removeAt(index);
        // Remove the cache data
        _rowDataMap.remove(rowOrder.rowId);
        newRows.insert(index, rowBuilder(rowOrder));
        updatedIndexs[rowOrder.rowId] = UpdatedIndex(index: index, rowId: rowOrder.rowId);
      }
    }

    _update(newRows, GridRowChangeReason.update(updatedIndexs));
  }

  void _update(List<GridRow> rows, GridRowChangeReason changeReason) {
    _rows = rows;
    _changeReason = changeReason;

    changeReason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      initial: (_) {},
    );
  }

  set rowData(Row rowData) {
    rowData.freeze();

    _rowDataMap[rowData.id] = rowData;
    final index = _rows.indexWhere((row) => row.rowId == rowData.id);
    if (index != -1) {
      if (_rows[index].data != rowData) {
        final row = _rows.removeAt(index).copyWith(data: rowData);
        _rows.insert(index, row);

        final UpdatedIndexs updatedIndexs = UpdatedIndexs();
        updatedIndexs[row.rowId] = UpdatedIndex(index: index, rowId: row.rowId);
        _changeReason = GridRowChangeReason.update(updatedIndexs);
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
class GridCellIdentifier with _$GridCellIdentifier {
  const factory GridCellIdentifier({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _GridCellIdentifier;
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

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
typedef UpdatedIndexs = LinkedHashMap<String, UpdatedIndex>;

class InsertedIndex {
  int index;
  String rowId;
  InsertedIndex({
    required this.index,
    required this.rowId,
  });
}

class DeletedIndex {
  int index;
  GridRow row;
  DeletedIndex({
    required this.index,
    required this.row,
  });
}

class UpdatedIndex {
  int index;
  String rowId;
  UpdatedIndex({
    required this.index,
    required this.rowId,
  });
}

@freezed
class GridRowChangeReason with _$GridRowChangeReason {
  const factory GridRowChangeReason.insert(InsertedIndexs items) = _Insert;
  const factory GridRowChangeReason.delete(DeletedIndexs items) = _Delete;
  const factory GridRowChangeReason.update(UpdatedIndexs indexs) = _Update;
  const factory GridRowChangeReason.initial() = InitialListState;
}

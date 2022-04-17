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

class RowsNotifier extends ChangeNotifier {
  List<GridRow> _rows = [];
  GridRowChangeReason _changeReason = const InitialListState();

  void updateRows(List<GridRow> rows, GridRowChangeReason changeReason) {
    _rows = rows;
    _changeReason = changeReason;

    changeReason.map(
      insert: (_) => notifyListeners(),
      delete: (_) => notifyListeners(),
      update: (_) => notifyListeners(),
      initial: (_) {},
    );
  }

  List<GridRow> get rows => _rows;
}

class GridRowCache {
  final String gridId;
  late GridRowListener _rowsListener;
  final RowsNotifier _rowNotifier = RowsNotifier();
  final HashMap<String, Row> _rowDataMap = HashMap();
  UnmodifiableListView<Field> _fields = UnmodifiableListView([]);

  GridRowCache({required this.gridId}) {
    _rowsListener = GridRowListener(gridId: gridId);
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

  List<GridRow> get clonedRows => [..._rowNotifier.rows];

  Future<void> dispose() async {
    await _rowsListener.stop();
    _rowNotifier.dispose();
  }

  void addListener({
    void Function(List<GridRow>, GridRowChangeReason)? onChanged,
    bool Function()? listenWhen,
  }) {
    listener() {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      if (onChanged != null) {
        onChanged(clonedRows, _rowNotifier._changeReason);
      }
    }

    _rowNotifier.addListener(listener);
  }

  void addRowListener({
    required String rowId,
    void Function(Row)? onUpdated,
    bool Function()? listenWhen,
  }) {
    _rowNotifier.addListener(() {
      if (onUpdated == null) {
        return;
      }

      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      _rowNotifier._changeReason.whenOrNull(update: (indexs) {
        final updatedIndex = indexs.firstWhereOrNull((updatedIndex) => updatedIndex.rowId == rowId);
        final row = _rowDataMap[rowId];
        if (updatedIndex != null && row != null) {
          onUpdated(row);
        }
      });
    });
  }

  Future<Option<Row>> getRowData(String rowId) async {
    final Row? data = _rowDataMap[rowId];
    if (data != null) {
      return Future(() => Some(data));
    }

    final payload = RowIdentifierPayload.create()
      ..gridId = gridId
      ..rowId = rowId;

    final result = await GridEventGetRow(payload).send();
    return Future(() {
      return result.fold(
        (data) {
          data.freeze();
          _rowDataMap[data.id] = data;
          return Some(data);
        },
        (err) {
          Log.error(err);
          return none();
        },
      );
    });
  }

  void updateWithBlock(List<GridBlockOrder> blocks, UnmodifiableListView<Field> fields) {
    _fields = fields;
    final newRows = blocks.expand((block) => block.rowOrders).map((rowOrder) {
      return GridRow.fromBlockRow(gridId, rowOrder, _fields);
    }).toList();

    _rowNotifier.updateRows(newRows, const GridRowChangeReason.initial());
  }

  void _deleteRows(List<RowOrder> deletedRows) {
    if (deletedRows.isEmpty) {
      return;
    }

    final List<GridRow> newRows = [];
    final DeletedIndexs deletedIndex = [];
    final Map<String, RowOrder> deletedRowMap = {for (var rowOrder in deletedRows) rowOrder.rowId: rowOrder};

    _rowNotifier.rows.asMap().forEach((index, row) {
      if (deletedRowMap[row.rowId] == null) {
        newRows.add(row);
      } else {
        deletedIndex.add(DeletedIndex(index: index, row: row));
      }
    });

    _rowNotifier.updateRows(newRows, GridRowChangeReason.delete(deletedIndex));
  }

  void _insertRows(List<IndexRowOrder> createdRows) {
    if (createdRows.isEmpty) {
      return;
    }

    InsertedIndexs insertIndexs = [];
    final List<GridRow> newRows = _rowNotifier.rows;
    for (final createdRow in createdRows) {
      final gridRow = GridRow.fromBlockRow(gridId, createdRow.rowOrder, _fields);
      insertIndexs.add(
        InsertedIndex(
          index: createdRow.index,
          rowId: gridRow.rowId,
        ),
      );
      newRows.insert(createdRow.index, gridRow);
    }
    _rowNotifier.updateRows(newRows, GridRowChangeReason.insert(insertIndexs));
  }

  void _updateRows(List<RowOrder> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final UpdatedIndexs updatedIndexs = [];
    final List<GridRow> newRows = _rowNotifier.rows;
    for (final rowOrder in updatedRows) {
      final index = newRows.indexWhere((row) => row.rowId == rowOrder.rowId);
      if (index != -1) {
        newRows.removeAt(index);
        newRows.insert(index, GridRow.fromBlockRow(gridId, rowOrder, _fields));
        _rowDataMap.remove(rowOrder.rowId);
        updatedIndexs.add(UpdatedIndex(index: index, rowId: rowOrder.rowId));
      }
    }

    _rowNotifier.updateRows(newRows, GridRowChangeReason.update(updatedIndexs));
  }
}

@freezed
class GridCellIdentifier with _$GridCellIdentifier {
  const factory GridCellIdentifier({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _CellData;
}

@freezed
class GridRow with _$GridRow {
  const factory GridRow({
    required String gridId,
    required String rowId,
    required List<Field> fields,
    required double height,
    required Future<Option<Row>> data,
  }) = _GridRow;

  factory GridRow.fromBlockRow(String gridId, RowOrder row, List<Field> fields) {
    return GridRow(
      gridId: gridId,
      fields: fields,
      rowId: row.rowId,
      data: Future(() => none()),
      height: row.height.toDouble(),
    );
  }
}

typedef InsertedIndexs = List<InsertedIndex>;
typedef DeletedIndexs = List<DeletedIndex>;
typedef UpdatedIndexs = List<UpdatedIndex>;

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

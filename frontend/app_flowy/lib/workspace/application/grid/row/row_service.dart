import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

class GridRowCache {
  final String gridId;
  UnmodifiableListView<Field> _fields = UnmodifiableListView([]);
  HashMap<String, Row> rowDataMap = HashMap();

  List<GridRow> _rows = [];

  GridRowCache({required this.gridId});

  List<GridRow> get rows => [..._rows];

  Future<Option<Row>> getRowData(String rowId) async {
    final Row? data = rowDataMap[rowId];
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
          rowDataMap[data.id] = data;
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
    _rows = blocks.expand((block) => block.rowOrders).map((rowOrder) {
      return GridRow.fromBlockRow(gridId, rowOrder, _fields);
    }).toList();
  }

  void updateFields(UnmodifiableListView<Field> fields) {
    if (fields.isEmpty) {
      return;
    }

    _fields = fields;
    _rows = _rows.map((row) => row.copyWith(fields: fields)).toList();
  }

  Option<GridListState> deleteRows(List<RowOrder> deletedRows) {
    if (deletedRows.isEmpty) {
      return none();
    }

    final List<GridRow> newRows = [];
    final DeletedIndex deletedIndex = [];
    final Map<String, RowOrder> deletedRowMap = {for (var rowOrder in deletedRows) rowOrder.rowId: rowOrder};
    _rows.asMap().forEach((index, value) {
      if (deletedRowMap[value.rowId] == null) {
        newRows.add(value);
      } else {
        deletedIndex.add(Tuple2(index, value));
      }
    });
    _rows = newRows;

    return Some(GridListState.delete(deletedIndex));
  }

  Option<GridListState> insertRows(List<IndexRowOrder> createdRows) {
    if (createdRows.isEmpty) {
      return none();
    }

    InsertedIndexs insertIndexs = [];
    for (final createdRow in createdRows) {
      final gridRow = GridRow.fromBlockRow(gridId, createdRow.rowOrder, _fields);
      insertIndexs.add(Tuple2(createdRow.index, gridRow.rowId));
      _rows.insert(createdRow.index, gridRow);
    }

    return Some(GridListState.insert(insertIndexs));
  }

  void updateRows(List<RowOrder> updatedRows) {
    if (updatedRows.isEmpty) {
      return;
    }

    final List<int> updatedIndexs = [];
    for (final updatedRow in updatedRows) {
      final index = _rows.indexWhere((row) => row.rowId == updatedRow.rowId);
      if (index != -1) {
        _rows.removeAt(index);
        _rows.insert(index, _toRowData(updatedRow));
        updatedIndexs.add(index);
      }
    }
  }

  GridRow _toRowData(RowOrder rowOrder) {
    return GridRow.fromBlockRow(gridId, rowOrder, _fields);
  }
}

@freezed
class CellData with _$CellData {
  const factory CellData({
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

typedef InsertedIndexs = List<Tuple2<int, String>>;
typedef DeletedIndex = List<Tuple2<int, GridRow>>;

@freezed
class GridListState with _$GridListState {
  const factory GridListState.insert(InsertedIndexs items) = _Insert;
  const factory GridListState.delete(DeletedIndex items) = _Delete;
  const factory GridListState.initial() = InitialListState;
}

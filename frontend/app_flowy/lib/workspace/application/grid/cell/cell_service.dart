import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';

class CellService {
  CellService();

  Future<Either<void, FlowyError>> updateCell({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String data,
  }) {
    final payload = CellChangeset.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..data = data;
    return GridEventUpdateCell(payload).send();
  }

  Future<Either<Cell, FlowyError>> getCell({
    required String gridId,
    required String fieldId,
    required String rowId,
  }) {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
    return GridEventGetCell(payload).send();
  }
}

class CellCache {
  final CellService _cellService;
  final HashMap<String, Cell> _cellDataMap = HashMap();

  CellCache() : _cellService = CellService();

  Future<Option<Cell>> getCellData(GridCellIdentifier identifier) async {
    final cellId = _cellId(identifier);
    final Cell? data = _cellDataMap[cellId];
    if (data != null) {
      return Future(() => Some(data));
    }

    final result = await _cellService.getCell(
      gridId: identifier.gridId,
      fieldId: identifier.field.id,
      rowId: identifier.rowId,
    );

    return result.fold(
      (cell) {
        _cellDataMap[_cellId(identifier)] = cell;
        return Some(cell);
      },
      (err) {
        Log.error(err);
        return none();
      },
    );
  }

  String _cellId(GridCellIdentifier identifier) {
    return "${identifier.rowId}/${identifier.field.id}";
  }
}

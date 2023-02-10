import 'dart:async';
import 'dart:collection';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_listener.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'dart:convert' show utf8;

import '../../field/field_controller.dart';
import '../../field/type_option/type_option_context.dart';
import 'cell_field_notifier.dart';
part 'cell_service.freezed.dart';
part 'cell_data_loader.dart';
part 'cell_controller.dart';
part 'cell_cache.dart';
part 'cell_data_persistence.dart';

// key: rowId

class CellService {
  CellService();

  Future<Either<void, FlowyError>> updateCell({
    required GridCellIdentifier cellId,
    required String data,
  }) {
    final payload = CellChangesetPB.create()
      ..databaseId = cellId.databaseId
      ..fieldId = cellId.fieldId
      ..rowId = cellId.rowId
      ..typeCellData = data;
    return DatabaseEventUpdateCell(payload).send();
  }

  Future<Either<CellPB, FlowyError>> getCell({
    required GridCellIdentifier cellId,
  }) {
    final payload = CellIdPB.create()
      ..databaseId = cellId.databaseId
      ..fieldId = cellId.fieldId
      ..rowId = cellId.rowId;
    return DatabaseEventGetCell(payload).send();
  }
}

/// Id of the cell
/// We can locate the cell by using database + rowId + field.id.
@freezed
class GridCellIdentifier with _$GridCellIdentifier {
  const factory GridCellIdentifier({
    required String databaseId,
    required String rowId,
    required FieldInfo fieldInfo,
  }) = _GridCellIdentifier;

  // ignore: unused_element
  const GridCellIdentifier._();

  String get fieldId => fieldInfo.id;

  FieldType get fieldType => fieldInfo.fieldType;

  ValueKey key() {
    return ValueKey("$rowId$fieldId${fieldInfo.fieldType}");
  }
}

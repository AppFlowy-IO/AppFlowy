import 'dart:async';
import 'dart:collection';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option_entities.pb.dart';
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
      ..gridId = cellId.gridId
      ..fieldId = cellId.fieldId
      ..rowId = cellId.rowId
      ..content = data;
    return GridEventUpdateCell(payload).send();
  }

  Future<Either<CellPB, FlowyError>> getCell({
    required GridCellIdentifier cellId,
  }) {
    final payload = CellPathPB.create()
      ..gridId = cellId.gridId
      ..fieldId = cellId.fieldId
      ..rowId = cellId.rowId;
    return GridEventGetCell(payload).send();
  }
}

/// Id of the cell
/// We can locate the cell by using gridId + rowId + field.id.
@freezed
class GridCellIdentifier with _$GridCellIdentifier {
  const factory GridCellIdentifier({
    required String gridId,
    required String rowId,
    required GridFieldInfo fieldInfo,
  }) = _GridCellIdentifier;

  // ignore: unused_element
  const GridCellIdentifier._();

  String get fieldId => fieldInfo.id;

  FieldType get fieldType => fieldInfo.fieldType;

  ValueKey key() {
    return ValueKey("$rowId$fieldId${fieldInfo.fieldType}");
  }
}

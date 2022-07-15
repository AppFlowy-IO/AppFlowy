import 'dart:async';
import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/application/grid/cell/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'dart:convert' show utf8;

import 'cell_field_notifier.dart';
part 'cell_service.freezed.dart';
part 'cell_data_loader.dart';
part 'context_builder.dart';
part 'cache.dart';
part 'cell_data_persistence.dart';

// key: rowId

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
      ..content = data;
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

@freezed
class GridCell with _$GridCell {
  const factory GridCell({
    required String gridId,
    required String rowId,
    required Field field,
  }) = _GridCell;

  // ignore: unused_element
  const GridCell._();

  String cellId() {
    return rowId + field.id + "${field.fieldType}";
  }
}

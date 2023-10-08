import 'dart:collection';
import 'dart:convert';

import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/cell_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cell_service.freezed.dart';
part 'cell_data_loader.dart';
part 'cell_cache.dart';
part 'cell_data_persistence.dart';

class CellBackendService {
  CellBackendService();

  Future<Either<void, FlowyError>> updateCell({
    required DatabaseCellContext cellContext,
    required String data,
  }) {
    final payload = CellChangesetPB.create()
      ..viewId = cellContext.viewId
      ..fieldId = cellContext.fieldId
      ..rowId = cellContext.rowId
      ..cellChangeset = data;
    return DatabaseEventUpdateCell(payload).send();
  }

  Future<Either<CellPB, FlowyError>> getCell({
    required DatabaseCellContext cellContext,
  }) {
    final payload = CellIdPB.create()
      ..viewId = cellContext.viewId
      ..fieldId = cellContext.fieldId
      ..rowId = cellContext.rowId;
    return DatabaseEventGetCell(payload).send();
  }
}

/// We can locate the cell by using database + rowId + field.id.
@freezed
class DatabaseCellContext with _$DatabaseCellContext {
  const factory DatabaseCellContext({
    required String viewId,
    required RowMetaPB rowMeta,
    required FieldPB field,
  }) = _DatabaseCellContext;

  const DatabaseCellContext._();

  String get rowId => rowMeta.id;

  String get fieldId => field.id;

  FieldType get fieldType => field.fieldType;

  ValueKey key() {
    return ValueKey("${rowMeta.id}$fieldId${field.fieldType}");
  }

  /// Only the primary field can have an emoji.
  String? get emoji => field.isPrimary ? rowMeta.icon : null;

  /// Determines whether a database cell context should be visible.
  /// It will be visible when the field is not hidden or when hidden fields
  /// should be shown.
  bool isVisible({bool showHiddenFields = false}) {
    return showHiddenFields || field.visibility != FieldVisibility.AlwaysHidden;
  }
}

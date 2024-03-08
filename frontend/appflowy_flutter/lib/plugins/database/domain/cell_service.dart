import 'dart:async';

import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import '../application/cell/cell_controller.dart';

class CellBackendService {
  CellBackendService();

  static Future<FlowyResult<void, FlowyError>> updateCell({
    required String viewId,
    required CellContext cellContext,
    required String data,
  }) {
    final payload = CellChangesetPB()
      ..viewId = viewId
      ..fieldId = cellContext.fieldId
      ..rowId = cellContext.rowId
      ..cellChangeset = data;
    return DatabaseEventUpdateCell(payload).send();
  }

  static Future<FlowyResult<CellPB, FlowyError>> getCell({
    required String viewId,
    required CellContext cellContext,
  }) {
    final payload = CellIdPB()
      ..viewId = viewId
      ..fieldId = cellContext.fieldId
      ..rowId = cellContext.rowId;
    return DatabaseEventGetCell(payload).send();
  }
}

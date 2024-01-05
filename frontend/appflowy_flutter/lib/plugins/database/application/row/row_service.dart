import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

import '../field/field_info.dart';

typedef RowId = String;

class RowBackendService {
  final String viewId;

  RowBackendService({
    required this.viewId,
  });

  static Future<Either<RowMetaPB, FlowyError>> createRow({
    required String viewId,
    String? groupId,
    void Function(RowDataBuilder builder)? withCells,
    OrderObjectPositionTypePB? position,
    String? targetRowId,
  }) {
    final payload = CreateRowPayloadPB(
      viewId: viewId,
      groupId: groupId,
      rowPosition: OrderObjectPositionPB(
        position: position,
        objectId: targetRowId,
      ),
    );

    Map<String, String>? cellDataByFieldId;

    if (withCells != null) {
      final rowBuilder = RowDataBuilder();
      withCells(rowBuilder);
      cellDataByFieldId = rowBuilder.build();
    }

    if (cellDataByFieldId != null) {
      payload.data = RowDataPB(cellDataByFieldId: cellDataByFieldId);
    }

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<RowMetaPB, FlowyError>> createRowBefore(RowId rowId) {
    return createRow(
      viewId: viewId,
      position: OrderObjectPositionTypePB.Before,
      targetRowId: rowId,
    );
  }

  Future<Either<RowMetaPB, FlowyError>> createRowAfter(RowId rowId) {
    return createRow(
      viewId: viewId,
      position: OrderObjectPositionTypePB.After,
      targetRowId: rowId,
    );
  }

  Future<Either<OptionalRowPB, FlowyError>> getRow(RowId rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRow(payload).send();
  }

  Future<Either<RowMetaPB, FlowyError>> getRowMeta(RowId rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRowMeta(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateMeta({
    required String rowId,
    String? iconURL,
    String? coverURL,
    bool? isDocumentEmpty,
  }) {
    final payload = UpdateRowMetaChangesetPB.create()
      ..viewId = viewId
      ..id = rowId;

    if (iconURL != null) {
      payload.iconUrl = iconURL;
    }
    if (coverURL != null) {
      payload.coverUrl = coverURL;
    }

    if (isDocumentEmpty != null) {
      payload.isDocumentEmpty = isDocumentEmpty;
    }

    return DatabaseEventUpdateRowMeta(payload).send();
  }

  static Future<Either<Unit, FlowyError>> deleteRow(
    String viewId,
    RowId rowId,
  ) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventDeleteRow(payload).send();
  }

  static Future<Either<Unit, FlowyError>> duplicateRow(
    String viewId,
    RowId rowId,
  ) {
    final payload = RowIdPB(
      viewId: viewId,
      rowId: rowId,
    );

    return DatabaseEventDuplicateRow(payload).send();
  }
}

class RowDataBuilder {
  final _cellDataByFieldId = <String, String>{};

  void insertText(FieldInfo fieldInfo, String text) {
    assert(fieldInfo.fieldType == FieldType.RichText);
    _cellDataByFieldId[fieldInfo.field.id] = text;
  }

  void insertNumber(FieldInfo fieldInfo, int num) {
    assert(fieldInfo.fieldType == FieldType.Number);
    _cellDataByFieldId[fieldInfo.field.id] = num.toString();
  }

  void insertDate(FieldInfo fieldInfo, DateTime date) {
    assert(fieldInfo.fieldType == FieldType.DateTime);
    final timestamp = date.millisecondsSinceEpoch ~/ 1000;
    _cellDataByFieldId[fieldInfo.field.id] = timestamp.toString();
  }

  Map<String, String> build() {
    return _cellDataByFieldId;
  }
}

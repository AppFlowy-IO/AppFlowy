import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import '../field/field_info.dart';

typedef RowId = String;

class RowBackendService {
  RowBackendService({required this.viewId});

  final String viewId;

  static Future<FlowyResult<RowMetaPB, FlowyError>> createRow({
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

    if (withCells != null) {
      final rowBuilder = RowDataBuilder();
      withCells(rowBuilder);
      payload.data.addAll(rowBuilder.build());
    }

    return DatabaseEventCreateRow(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> initRow(RowId rowId) async {
    final payload = RowIdPB()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventInitRow(payload).send();
  }

  Future<FlowyResult<RowMetaPB, FlowyError>> createRowBefore(RowId rowId) {
    return createRow(
      viewId: viewId,
      position: OrderObjectPositionTypePB.Before,
      targetRowId: rowId,
    );
  }

  Future<FlowyResult<RowMetaPB, FlowyError>> createRowAfter(RowId rowId) {
    return createRow(
      viewId: viewId,
      position: OrderObjectPositionTypePB.After,
      targetRowId: rowId,
    );
  }

  static Future<FlowyResult<RowMetaPB, FlowyError>> getRow({
    required String viewId,
    required String rowId,
  }) {
    final payload = RowIdPB()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRowMeta(payload).send();
  }

  Future<FlowyResult<RowMetaPB, FlowyError>> getRowMeta(RowId rowId) {
    final payload = RowIdPB.create()
      ..viewId = viewId
      ..rowId = rowId;

    return DatabaseEventGetRowMeta(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateMeta({
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

  static Future<FlowyResult<void, FlowyError>> deleteRows(
    String viewId,
    List<RowId> rowIds,
  ) {
    final payload = RepeatedRowIdPB.create()
      ..viewId = viewId
      ..rowIds.addAll(rowIds);

    return DatabaseEventDeleteRows(payload).send();
  }

  static Future<FlowyResult<void, FlowyError>> duplicateRow(
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

  void insertURL(FieldInfo fieldInfo, String url) {
    assert(fieldInfo.fieldType == FieldType.URL);
    _cellDataByFieldId[fieldInfo.field.id] = url;
  }

  Map<String, String> build() {
    return _cellDataByFieldId;
  }
}

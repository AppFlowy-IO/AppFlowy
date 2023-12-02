import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/board_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';

class DatabaseViewBackendService {
  final String viewId;
  DatabaseViewBackendService({
    required this.viewId,
  });

  /// Returns the datbaase id associated with the view.
  Future<Either<String, FlowyError>> getDatabaseId() async {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabaseId(payload)
        .send()
        .then((value) => value.leftMap((l) => l.value));
  }

  Future<Either<DatabasePB, FlowyError>> openDatabase() async {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabase(payload).send();
  }

  Future<Either<RowMetaPB, FlowyError>> createRow({
    RowId? startRowId,
    String? groupId,
    Map<String, String>? cellDataByFieldId,
    bool fromBeginning = false,
  }) {
    final payload = CreateRowPayloadPB.create()..viewId = viewId;

    if (!fromBeginning || startRowId != null) {
      payload.startRowId = startRowId ?? "";
    }

    if (groupId != null) {
      payload.groupId = groupId;
    }

    if (cellDataByFieldId != null && cellDataByFieldId.isNotEmpty) {
      payload.data = RowDataPB(cellDataByFieldId: cellDataByFieldId);
    }

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroupRow({
    required RowId fromRowId,
    required String fromGroupId,
    required String toGroupId,
    RowId? toRowId,
  }) {
    final payload = MoveGroupRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..fromGroupId = fromGroupId
      ..toGroupId = toGroupId;

    if (toRowId != null) {
      payload.toRowId = toRowId;
    }

    return DatabaseEventMoveGroupRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveRow({
    required String fromRowId,
    required String toRowId,
  }) {
    final payload = MoveRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..toRowId = toRowId;

    return DatabaseEventMoveRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveGroup({
    required String fromGroupId,
    required String toGroupId,
  }) {
    final payload = MoveGroupPayloadPB.create()
      ..viewId = viewId
      ..fromGroupId = fromGroupId
      ..toGroupId = toGroupId;

    return DatabaseEventMoveGroup(payload).send();
  }

  Future<Either<List<FieldPB>, FlowyError>> getFields({
    List<FieldIdPB>? fieldIds,
  }) {
    final payload = GetFieldPayloadPB.create()..viewId = viewId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return DatabaseEventGetFields(payload).send().then((result) {
      return result.fold((l) => left(l.items), (r) => right(r));
    });
  }

  Future<Either<DatabaseLayoutSettingPB, FlowyError>> getLayoutSetting(
    DatabaseLayoutPB layoutType,
  ) {
    final payload = DatabaseLayoutMetaPB.create()
      ..viewId = viewId
      ..layout = layoutType;
    return DatabaseEventGetLayoutSetting(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateLayoutSetting({
    required DatabaseLayoutPB layoutType,
    BoardLayoutSettingPB? boardLayoutSetting,
    CalendarLayoutSettingPB? calendarLayoutSetting,
  }) {
    final payload = LayoutSettingChangesetPB.create()
      ..viewId = viewId
      ..layoutType = layoutType;

    if (boardLayoutSetting != null) {
      payload.board = boardLayoutSetting;
    }

    if (calendarLayoutSetting != null) {
      payload.calendar = calendarLayoutSetting;
    }

    return DatabaseEventSetLayoutSetting(payload).send();
  }

  Future<Either<Unit, FlowyError>> closeView() {
    final request = ViewIdPB(value: viewId);
    return FolderEventCloseView(request).send();
  }

  Future<Either<RepeatedGroupPB, FlowyError>> loadGroups() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetGroups(payload).send();
  }
}

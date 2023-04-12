import 'package:appflowy_backend/protobuf/flowy-database/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group_changeset.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/row_entities.pb.dart';

class DatabaseViewBackendService {
  final String viewId;
  DatabaseViewBackendService({
    required this.viewId,
  });

  Future<Either<DatabasePB, FlowyError>> openGrid() async {
    await FolderEventSetLatestView(ViewIdPB(value: viewId)).send();

    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabase(payload).send();
  }

  Future<Either<RowPB, FlowyError>> createRow({
    String? startRowId,
    String? groupId,
    Map<String, String>? cellDataByFieldId,
  }) {
    var payload = CreateRowPayloadPB.create()..viewId = viewId;
    if (startRowId != null) {
      payload.startRowId = startRowId;
    }

    if (groupId != null) {
      payload.groupId = groupId;
    }

    if (cellDataByFieldId != null && cellDataByFieldId.isNotEmpty) {
      payload.data = RowDataPB(cellDataByFieldId: cellDataByFieldId);
    }

    return DatabaseEventCreateRow(payload).send();
  }

  Future<Either<Unit, FlowyError>> moveRow({
    required String fromRowId,
    required String toGroupId,
    String? toRowId,
  }) {
    var payload = MoveGroupRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..toGroupId = toGroupId;

    if (toRowId != null) {
      payload.toRowId = toRowId;
    }

    return DatabaseEventMoveGroupRow(payload).send();
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
    var payload = GetFieldPayloadPB.create()..viewId = viewId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return DatabaseEventGetFields(payload).send().then((result) {
      return result.fold((l) => left(l.items), (r) => right(r));
    });
  }

  Future<Either<LayoutSettingPB, FlowyError>> getLayoutSetting(
    LayoutTypePB layoutType,
  ) {
    final payload = DatabaseLayoutIdPB.create()
      ..viewId = viewId
      ..layout = layoutType;
    return DatabaseEventGetLayoutSetting(payload).send();
  }

  Future<Either<Unit, FlowyError>> updateLayoutSetting({
    CalendarLayoutSettingsPB? calendarLayoutSetting,
  }) {
    final layoutSetting = LayoutSettingPB.create();
    if (calendarLayoutSetting != null) {
      layoutSetting.calendar = calendarLayoutSetting;
    }

    final payload = UpdateLayoutSettingPB.create()
      ..viewId = viewId
      ..layoutSetting = layoutSetting;

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

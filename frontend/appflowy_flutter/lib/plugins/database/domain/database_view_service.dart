import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'layout_service.dart';

class DatabaseViewBackendService {
  DatabaseViewBackendService({required this.viewId});

  final String viewId;

  /// Returns the database id associated with the view.
  Future<FlowyResult<String, FlowyError>> getDatabaseId() async {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabaseId(payload)
        .send()
        .then((value) => value.map((l) => l.value));
  }

  static Future<FlowyResult<ViewPB, FlowyError>> updateLayout({
    required String viewId,
    required DatabaseLayoutPB layout,
  }) {
    final payload = UpdateViewPayloadPB.create()
      ..viewId = viewId
      ..layout = viewLayoutFromDatabaseLayout(layout);

    return FolderEventUpdateView(payload).send();
  }

  Future<FlowyResult<DatabasePB, FlowyError>> openDatabase() async {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetDatabase(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> moveGroupRow({
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

  Future<FlowyResult<void, FlowyError>> moveRow({
    required String fromRowId,
    required String toRowId,
  }) {
    final payload = MoveRowPayloadPB.create()
      ..viewId = viewId
      ..fromRowId = fromRowId
      ..toRowId = toRowId;

    return DatabaseEventMoveRow(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> moveGroup({
    required String fromGroupId,
    required String toGroupId,
  }) {
    final payload = MoveGroupPayloadPB.create()
      ..viewId = viewId
      ..fromGroupId = fromGroupId
      ..toGroupId = toGroupId;

    return DatabaseEventMoveGroup(payload).send();
  }

  Future<FlowyResult<List<FieldPB>, FlowyError>> getFields({
    List<FieldIdPB>? fieldIds,
  }) {
    final payload = GetFieldPayloadPB.create()..viewId = viewId;

    if (fieldIds != null) {
      payload.fieldIds = RepeatedFieldIdPB(items: fieldIds);
    }
    return DatabaseEventGetFields(payload).send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l.items),
        (r) => FlowyResult.failure(r),
      );
    });
  }

  Future<FlowyResult<DatabaseLayoutSettingPB, FlowyError>> getLayoutSetting(
    DatabaseLayoutPB layoutType,
  ) {
    final payload = DatabaseLayoutMetaPB.create()
      ..viewId = viewId
      ..layout = layoutType;
    return DatabaseEventGetLayoutSetting(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> updateLayoutSetting({
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

  Future<FlowyResult<void, FlowyError>> closeView() {
    final request = ViewIdPB(value: viewId);
    return FolderEventCloseView(request).send();
  }

  Future<FlowyResult<RepeatedGroupPB, FlowyError>> loadGroups() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventGetGroups(payload).send();
  }
}

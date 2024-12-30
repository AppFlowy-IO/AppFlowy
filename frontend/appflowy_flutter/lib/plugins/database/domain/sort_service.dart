import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class SortBackendService {
  SortBackendService({required this.viewId});

  final String viewId;

  Future<FlowyResult<List<SortPB>, FlowyError>> getAllSorts() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllSorts(payload).send().then((result) {
      return result.fold(
        (repeated) => FlowyResult.success(repeated.items),
        (r) => FlowyResult.failure(r),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> updateSort({
    required String sortId,
    required String fieldId,
    required SortConditionPB condition,
  }) {
    final insertSortPayload = UpdateSortPayloadPB.create()
      ..viewId = viewId
      ..sortId = sortId
      ..fieldId = fieldId
      ..condition = condition;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..updateSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l),
        (err) {
          Log.error(err);
          return FlowyResult.failure(err);
        },
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> insertSort({
    required String fieldId,
    required SortConditionPB condition,
  }) {
    final insertSortPayload = UpdateSortPayloadPB.create()
      ..fieldId = fieldId
      ..viewId = viewId
      ..condition = condition;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..updateSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l),
        (err) {
          Log.error(err);
          return FlowyResult.failure(err);
        },
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> reorderSort({
    required String fromSortId,
    required String toSortId,
  }) {
    final payload = DatabaseSettingChangesetPB()
      ..viewId = viewId
      ..reorderSort = (ReorderSortPayloadPB()
        ..viewId = viewId
        ..fromSortId = fromSortId
        ..toSortId = toSortId);

    return DatabaseEventUpdateDatabaseSetting(payload).send();
  }

  Future<FlowyResult<void, FlowyError>> deleteSort({
    required String sortId,
  }) {
    final deleteSortPayload = DeleteSortPayloadPB.create()
      ..sortId = sortId
      ..viewId = viewId;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..deleteSort = deleteSortPayload;

    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l),
        (err) {
          Log.error(err);
          return FlowyResult.failure(err);
        },
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> deleteAllSorts() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventDeleteAllSorts(payload).send().then((result) {
      return result.fold(
        (l) => FlowyResult.success(l),
        (err) {
          Log.error(err);
          return FlowyResult.failure(err);
        },
      );
    });
  }
}

import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';

class SortBackendService {
  final String viewId;

  SortBackendService({required this.viewId});

  Future<Either<List<SortPB>, FlowyError>> getAllSorts() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllSorts(payload).send().then((result) {
      return result.fold(
        (repeated) => left(repeated.items),
        (r) => right(r),
      );
    });
  }

  Future<Either<Unit, FlowyError>> updateSort({
    required String fieldId,
    required String sortId,
    required FieldType fieldType,
    required SortConditionPB condition,
  }) {
    final insertSortPayload = UpdateSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition
      ..sortId = sortId;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..updateSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => left(l),
        (err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> insertSort({
    required String fieldId,
    required FieldType fieldType,
    required SortConditionPB condition,
  }) {
    final insertSortPayload = UpdateSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..updateSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => left(l),
        (err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> deleteSort({
    required String fieldId,
    required String sortId,
    required FieldType fieldType,
  }) {
    final deleteSortPayload = DeleteSortPayloadPB.create()
      ..fieldId = fieldId
      ..sortId = sortId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..deleteSort = deleteSortPayload;

    return DatabaseEventUpdateDatabaseSetting(payload).send().then((result) {
      return result.fold(
        (l) => left(l),
        (err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> deleteAllSorts() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventDeleteAllSorts(payload).send().then((result) {
      return result.fold(
        (l) => left(l),
        (err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }
}

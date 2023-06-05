import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pb.dart';

class SortBackendService {
  final String viewId;

  SortBackendService({required this.viewId});

  Future<Either<List<SortPB>, FlowyError>> getAllSorts() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllSorts(payload).send().then((final result) {
      return result.fold(
        (final repeated) => left(repeated.items),
        (final r) => right(r),
      );
    });
  }

  Future<Either<Unit, FlowyError>> updateSort({
    required final String fieldId,
    required final String sortId,
    required final FieldType fieldType,
    required final SortConditionPB condition,
  }) {
    final insertSortPayload = AlterSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition
      ..sortId = sortId;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..alterSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((final result) {
      return result.fold(
        (final l) => left(l),
        (final err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> insertSort({
    required final String fieldId,
    required final FieldType fieldType,
    required final SortConditionPB condition,
  }) {
    final insertSortPayload = AlterSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..alterSort = insertSortPayload;
    return DatabaseEventUpdateDatabaseSetting(payload).send().then((final result) {
      return result.fold(
        (final l) => left(l),
        (final err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> deleteSort({
    required final String fieldId,
    required final String sortId,
    required final FieldType fieldType,
  }) {
    final deleteFilterPayload = DeleteSortPayloadPB.create()
      ..fieldId = fieldId
      ..sortId = sortId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..deleteSort = deleteFilterPayload;

    return DatabaseEventUpdateDatabaseSetting(payload).send().then((final result) {
      return result.fold(
        (final l) => left(l),
        (final err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }

  Future<Either<Unit, FlowyError>> deleteAllSorts() {
    final payload = DatabaseViewIdPB(value: viewId);
    return DatabaseEventDeleteAllSorts(payload).send().then((final result) {
      return result.fold(
        (final l) => left(l),
        (final err) {
          Log.error(err);
          return right(err);
        },
      );
    });
  }
}

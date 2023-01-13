import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/sort_entities.pb.dart';

class SortFFIService {
  final String viewId;

  SortFFIService({required this.viewId});

  Future<Either<List<SortPB>, FlowyError>> getAllSorts() {
    final payload = GridIdPB()..value = viewId;

    return GridEventGetAllSorts(payload).send().then((result) {
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
    required GridSortConditionPB condition,
  }) {
    var insertSortPayload = AlterSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition
      ..sortId = sortId;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..alterSort = insertSortPayload;
    return GridEventUpdateGridSetting(payload).send().then((result) {
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
    required GridSortConditionPB condition,
  }) {
    var insertSortPayload = AlterSortPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..condition = condition;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..alterSort = insertSortPayload;
    return GridEventUpdateGridSetting(payload).send().then((result) {
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
    final deleteFilterPayload = DeleteSortPayloadPB.create()
      ..fieldId = fieldId
      ..sortId = sortId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..deleteSort = deleteFilterPayload;

    return GridEventUpdateGridSetting(payload).send().then((result) {
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
    final payload = GridIdPB(value: viewId);
    return GridEventDeleteAllSorts(payload).send().then((result) {
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

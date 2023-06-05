import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/util.pb.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

class FilterBackendService {
  final String viewId;
  const FilterBackendService({required this.viewId});

  Future<Either<List<FilterPB>, FlowyError>> getAllFilters() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllFilters(payload).send().then((final result) {
      return result.fold(
        (final repeated) => left(repeated.items),
        (final r) => right(r),
      );
    });
  }

  Future<Either<Unit, FlowyError>> insertTextFilter({
    required final String fieldId,
    final String? filterId,
    required final TextFilterConditionPB condition,
    required final String content,
  }) {
    final filter = TextFilterPB()
      ..condition = condition
      ..content = content;

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.RichText,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertCheckboxFilter({
    required final String fieldId,
    final String? filterId,
    required final CheckboxFilterConditionPB condition,
  }) {
    final filter = CheckboxFilterPB()..condition = condition;

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.Checkbox,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertNumberFilter({
    required final String fieldId,
    final String? filterId,
    required final NumberFilterConditionPB condition,
    final String content = "",
  }) {
    final filter = NumberFilterPB()
      ..condition = condition
      ..content = content;

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.Number,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertDateFilter({
    required final String fieldId,
    final String? filterId,
    required final DateFilterConditionPB condition,
    final int? start,
    final int? end,
    final int? timestamp,
  }) {
    final filter = DateFilterPB();
    if (timestamp != null) {
      filter.timestamp = $fixnum.Int64(timestamp);
    } else {
      if (start != null && end != null) {
        filter.start = $fixnum.Int64(start);
        filter.end = $fixnum.Int64(end);
      } else {
        throw Exception(
          "Start and end should not be null if the timestamp is null",
        );
      }
    }

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.DateTime,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertURLFilter({
    required final String fieldId,
    final String? filterId,
    required final TextFilterConditionPB condition,
    final String content = "",
  }) {
    final filter = TextFilterPB()
      ..condition = condition
      ..content = content;

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.URL,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertSelectOptionFilter({
    required final String fieldId,
    required final FieldType fieldType,
    required final SelectOptionConditionPB condition,
    final String? filterId,
    final List<String> optionIds = const [],
  }) {
    final filter = SelectOptionFilterPB()
      ..condition = condition
      ..optionIds.addAll(optionIds);

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: fieldType,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertChecklistFilter({
    required final String fieldId,
    required final ChecklistFilterConditionPB condition,
    final String? filterId,
    final List<String> optionIds = const [],
  }) {
    final filter = ChecklistFilterPB()..condition = condition;

    return insertFilter(
      fieldId: fieldId,
      filterId: filterId,
      fieldType: FieldType.Checklist,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> insertFilter({
    required final String fieldId,
    final String? filterId,
    required final FieldType fieldType,
    required final List<int> data,
  }) {
    final insertFilterPayload = AlterFilterPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..data = data;

    if (filterId != null) {
      insertFilterPayload.filterId = filterId;
    }

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..alterFilter = insertFilterPayload;
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

  Future<Either<Unit, FlowyError>> deleteFilter({
    required final String fieldId,
    required final String filterId,
    required final FieldType fieldType,
  }) {
    final deleteFilterPayload = DeleteFilterPayloadPB.create()
      ..fieldId = fieldId
      ..filterId = filterId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..deleteFilter = deleteFilterPayload;

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
}

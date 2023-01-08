import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/checkbox_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/date_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/util.pb.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

class FilterFFIService {
  final String viewId;
  const FilterFFIService({required this.viewId});

  Future<Either<List<FilterPB>, FlowyError>> getAllFilters() {
    final payload = GridIdPB()..value = viewId;

    return GridEventGetAllFilters(payload).send().then((result) {
      return result.fold(
        (repeated) => left(repeated.items),
        (r) => right(r),
      );
    });
  }

  Future<Either<Unit, FlowyError>> insertTextFilter({
    required String fieldId,
    String? filterId,
    required TextFilterConditionPB condition,
    required String content,
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
    required String fieldId,
    String? filterId,
    required CheckboxFilterConditionPB condition,
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
    required String fieldId,
    String? filterId,
    required NumberFilterConditionPB condition,
    String content = "",
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
    required String fieldId,
    String? filterId,
    required DateFilterConditionPB condition,
    int? start,
    int? end,
    int? timestamp,
  }) {
    var filter = DateFilterPB();
    if (timestamp != null) {
      filter.timestamp = $fixnum.Int64(timestamp);
    } else {
      if (start != null && end != null) {
        filter.start = $fixnum.Int64(start);
        filter.end = $fixnum.Int64(end);
      } else {
        throw Exception(
            "Start and end should not be null if the timestamp is null");
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
    required String fieldId,
    String? filterId,
    required TextFilterConditionPB condition,
    String content = "",
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
    required String fieldId,
    required FieldType fieldType,
    required SelectOptionConditionPB condition,
    String? filterId,
    List<String> optionIds = const [],
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
    required String fieldId,
    required ChecklistFilterConditionPB condition,
    String? filterId,
    List<String> optionIds = const [],
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
    required String fieldId,
    String? filterId,
    required FieldType fieldType,
    required List<int> data,
  }) {
    var insertFilterPayload = AlterFilterPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..data = data;

    if (filterId != null) {
      insertFilterPayload.filterId = filterId;
    }

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..alterFilter = insertFilterPayload;
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

  Future<Either<Unit, FlowyError>> deleteFilter({
    required String fieldId,
    required String filterId,
    required FieldType fieldType,
  }) {
    TextFilterConditionPB.DoesNotContain.value;

    final deleteFilterPayload = DeleteFilterPayloadPB.create()
      ..fieldId = fieldId
      ..filterId = filterId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..deleteFilter = deleteFilterPayload;

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
}

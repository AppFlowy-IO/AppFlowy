import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checklist_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_filter.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/util.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

class FilterBackendService {
  const FilterBackendService({required this.viewId});

  final String viewId;

  Future<FlowyResult<List<FilterPB>, FlowyError>> getAllFilters() {
    final payload = DatabaseViewIdPB()..value = viewId;

    return DatabaseEventGetAllFilters(payload).send().then((result) {
      return result.fold(
        (repeated) => FlowyResult.success(repeated.items),
        (r) => FlowyResult.failure(r),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> insertTextFilter({
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

  Future<FlowyResult<void, FlowyError>> insertCheckboxFilter({
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

  Future<FlowyResult<void, FlowyError>> insertNumberFilter({
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

  Future<FlowyResult<void, FlowyError>> insertDateFilter({
    required String fieldId,
    String? filterId,
    required DateFilterConditionPB condition,
    required FieldType fieldType,
    int? start,
    int? end,
    int? timestamp,
  }) {
    assert(
      [
        FieldType.DateTime,
        FieldType.LastEditedTime,
        FieldType.CreatedTime,
      ].contains(fieldType),
    );

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
      fieldType: fieldType,
      data: filter.writeToBuffer(),
    );
  }

  Future<FlowyResult<void, FlowyError>> insertURLFilter({
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

  Future<FlowyResult<void, FlowyError>> insertSelectOptionFilter({
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

  Future<FlowyResult<void, FlowyError>> insertChecklistFilter({
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

  Future<FlowyResult<void, FlowyError>> insertFilter({
    required String fieldId,
    String? filterId,
    required FieldType fieldType,
    required List<int> data,
  }) {
    final insertFilterPayload = UpdateFilterPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..viewId = viewId
      ..data = data;

    if (filterId != null) {
      insertFilterPayload.filterId = filterId;
    }

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..updateFilter = insertFilterPayload;
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

  Future<FlowyResult<void, FlowyError>> deleteFilter({
    required String fieldId,
    required String filterId,
    required FieldType fieldType,
  }) {
    final deleteFilterPayload = DeleteFilterPayloadPB.create()
      ..fieldId = fieldId
      ..filterId = filterId
      ..viewId = viewId
      ..fieldType = fieldType;

    final payload = DatabaseSettingChangesetPB.create()
      ..viewId = viewId
      ..deleteFilter = deleteFilterPayload;

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
}

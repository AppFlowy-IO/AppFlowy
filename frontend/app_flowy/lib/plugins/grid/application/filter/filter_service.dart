import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;

class FilterFFIService {
  final String viewId;
  const FilterFFIService({required this.viewId});

  Future<Either<Unit, FlowyError>> createTextFilter({
    required String fieldId,
    required TextFilterCondition condition,
    String content = "",
  }) {
    final filter = TextFilterPB()
      ..condition = condition
      ..content = content;

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.RichText,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createCheckboxFilter({
    required String fieldId,
    required CheckboxFilterCondition condition,
  }) {
    final filter = CheckboxFilterPB()..condition = condition;

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.Checkbox,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createNumberFilter({
    required String fieldId,
    required NumberFilterCondition condition,
    String content = "",
  }) {
    final filter = NumberFilterPB()
      ..condition = condition
      ..content = content;

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.Number,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createDateFilter({
    required String fieldId,
    required DateFilterCondition condition,
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

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.DateTime,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createURLFilter({
    required String fieldId,
    required TextFilterCondition condition,
    String content = "",
  }) {
    final filter = TextFilterPB()
      ..condition = condition
      ..content = content;

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.URL,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createSingleSelectFilter({
    required String fieldId,
    required SelectOptionCondition condition,
    List<String> optionIds = const [],
  }) {
    final filter = SelectOptionFilterPB()
      ..condition = condition
      ..optionIds.addAll(optionIds);

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.SingleSelect,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createMultiSelectFilter({
    required String fieldId,
    required SelectOptionCondition condition,
    List<String> optionIds = const [],
  }) {
    final filter = SelectOptionFilterPB()
      ..condition = condition
      ..optionIds.addAll(optionIds);

    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.MultiSelect,
      data: filter.writeToBuffer(),
    );
  }

  Future<Either<Unit, FlowyError>> createFilter({
    required String fieldId,
    required FieldType fieldType,
    required List<int> data,
  }) {
    TextFilterCondition.DoesNotContain.value;

    final insertFilterPayload = CreateFilterPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..data = data;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..insertFilter = insertFilterPayload;
    return GridEventUpdateGridSetting(payload).send();
  }
}

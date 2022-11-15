import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_filter.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_option_filter.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/util.pb.dart';

class FilterFFIService {
  final String viewId;
  const FilterFFIService({required this.viewId});

  Future<Either<Unit, FlowyError>> createTextFilter({
    required String fieldId,
    required TextFilterCondition condition,
    String content = "",
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.RichText,
      condition: condition.value,
      content: content,
    );
  }

  Future<Either<Unit, FlowyError>> createCheckboxFilter({
    required String fieldId,
    required CheckboxFilterCondition condition,
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.Checkbox,
      condition: condition.value,
    );
  }

  Future<Either<Unit, FlowyError>> createNumberFilter({
    required String fieldId,
    required NumberFilterCondition condition,
    String content = "",
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.Checkbox,
      condition: condition.value,
      content: content,
    );
  }

  Future<Either<Unit, FlowyError>> createDateFilter({
    required String fieldId,
    required DateFilterCondition condition,
    String content = "",
  }) {
    throw UnimplementedError();
  }

  Future<Either<Unit, FlowyError>> createURLFilter({
    required String fieldId,
    required TextFilterCondition condition,
    String content = "",
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.URL,
      condition: condition.value,
      content: content,
    );
  }

  Future<Either<Unit, FlowyError>> createSingleSelectFilter({
    required String fieldId,
    required SelectOptionCondition condition,
    List<String> optionIds = const [],
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.SingleSelect,
      condition: condition.value,
    );
  }

  Future<Either<Unit, FlowyError>> createMultiSelectFilter({
    required String fieldId,
    required SelectOptionCondition condition,
    List<String> optionIds = const [],
  }) {
    return createFilter(
      fieldId: fieldId,
      fieldType: FieldType.MultiSelect,
      condition: condition.value,
    );
  }

  Future<Either<Unit, FlowyError>> createFilter({
    required String fieldId,
    required FieldType fieldType,
    required int condition,
    String content = "",
  }) {
    TextFilterCondition.DoesNotContain.value;

    final insertFilterPayload = CreateFilterPayloadPB.create()
      ..fieldId = fieldId
      ..fieldType = fieldType
      ..condition = condition
      ..content = content;

    final payload = GridSettingChangesetPB.create()
      ..gridId = viewId
      ..insertFilter = insertFilterPayload;
    return GridEventUpdateGridSetting(payload).send();
  }
}

import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'field_info.freezed.dart';

@freezed
class FieldInfo with _$FieldInfo {
  const FieldInfo._();

  const factory FieldInfo({
    required FieldPB field,
    required FieldSettingsPB? fieldSettings,
    required bool isGroupField,
    required bool hasFilter,
    required bool hasSort,
  }) = _FieldInfo;

  String get id => field.id;

  FieldType get fieldType => field.fieldType;

  String get name => field.name;

  bool get isPrimary => field.isPrimary;

  FieldVisibility? get visibility => fieldSettings?.visibility;

  factory FieldInfo.initial(FieldPB field) => FieldInfo(
        field: field,
        fieldSettings: null,
        hasFilter: false,
        hasSort: false,
        isGroupField: false,
      );

  bool get canBeGroup {
    switch (field.fieldType) {
      case FieldType.URL:
      case FieldType.Checkbox:
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
      case FieldType.DateTime:
        return true;
      default:
        return false;
    }
  }

  bool get canCreateFilter {
    if (hasFilter) return false;

    switch (field.fieldType) {
      case FieldType.Checkbox:
      case FieldType.MultiSelect:
      case FieldType.RichText:
      case FieldType.SingleSelect:
      case FieldType.Checklist:
        return true;
      default:
        return false;
    }
  }

  bool get canCreateSort {
    if (hasSort) return false;

    switch (field.fieldType) {
      case FieldType.RichText:
      case FieldType.Checkbox:
      case FieldType.Number:
      case FieldType.DateTime:
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return true;
      default:
        return false;
    }
  }
}

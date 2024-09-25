import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_info.freezed.dart';

@freezed
class FieldInfo with _$FieldInfo {
  const FieldInfo._();

  factory FieldInfo.initial(FieldPB field) => FieldInfo(
        field: field,
        fieldSettings: null,
        hasFilter: false,
        hasSort: false,
        isGroupField: false,
      );

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

  double? get width => fieldSettings?.width.toDouble();

  FieldVisibility? get visibility => fieldSettings?.visibility;

  bool? get wrapCellContent => fieldSettings?.wrapCellContent;
}

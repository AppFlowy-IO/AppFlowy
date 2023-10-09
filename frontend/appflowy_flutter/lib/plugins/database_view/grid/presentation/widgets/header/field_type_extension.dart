import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
  FlowySvgData icon() {
    return switch (this) {
      FieldType.Checkbox => FlowySvgs.checkbox_s,
      FieldType.DateTime ||
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        FlowySvgs.date_s,
      FieldType.MultiSelect => FlowySvgs.multiselect_s,
      FieldType.Number => FlowySvgs.numbers_s,
      FieldType.RichText => FlowySvgs.text_s,
      FieldType.SingleSelect => FlowySvgs.status_s,
      FieldType.URL => FlowySvgs.attach_s,
      FieldType.Checklist => FlowySvgs.checklist_s,
      _ => throw UnimplementedError(),
    };
  }

  String title() {
    return switch (this) {
      FieldType.Checkbox => LocaleKeys.grid_field_checkboxFieldName.tr(),
      FieldType.DateTime => LocaleKeys.grid_field_dateFieldName.tr(),
      FieldType.LastEditedTime => LocaleKeys.grid_field_updatedAtFieldName.tr(),
      FieldType.CreatedTime => LocaleKeys.grid_field_createdAtFieldName.tr(),
      FieldType.MultiSelect => LocaleKeys.grid_field_multiSelectFieldName.tr(),
      FieldType.Number => LocaleKeys.grid_field_numberFieldName.tr(),
      FieldType.RichText => LocaleKeys.grid_field_textFieldName.tr(),
      FieldType.SingleSelect =>
        LocaleKeys.grid_field_singleSelectFieldName.tr(),
      FieldType.URL => LocaleKeys.grid_field_urlFieldName.tr(),
      FieldType.Checklist => LocaleKeys.grid_field_checklistFieldName.tr(),
      _ => throw UnimplementedError(),
    };
  }

  bool hasTypeOptions() {
    return switch (this) {
      FieldType.DateTime ||
      FieldType.LastEditedTime ||
      FieldType.CreatedTime ||
      FieldType.Number ||
      FieldType.SingleSelect ||
      FieldType.MultiSelect =>
        true,
      FieldType.Checkbox ||
      FieldType.Checklist ||
      FieldType.RichText ||
      FieldType.URL =>
        false,
      _ => throw UnimplementedError(),
    };
  }
}

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';

extension FieldTypeExtension on FieldType {
  String get i18n => switch (this) {
        FieldType.RichText => LocaleKeys.grid_field_textFieldName.tr(),
        FieldType.Number => LocaleKeys.grid_field_numberFieldName.tr(),
        FieldType.DateTime => LocaleKeys.grid_field_dateFieldName.tr(),
        FieldType.SingleSelect =>
          LocaleKeys.grid_field_singleSelectFieldName.tr(),
        FieldType.MultiSelect =>
          LocaleKeys.grid_field_multiSelectFieldName.tr(),
        FieldType.Checkbox => LocaleKeys.grid_field_checkboxFieldName.tr(),
        FieldType.Checklist => LocaleKeys.grid_field_checklistFieldName.tr(),
        FieldType.URL => LocaleKeys.grid_field_urlFieldName.tr(),
        FieldType.LastEditedTime =>
          LocaleKeys.grid_field_updatedAtFieldName.tr(),
        FieldType.CreatedTime => LocaleKeys.grid_field_createdAtFieldName.tr(),
        _ => throw UnimplementedError(),
      };

  FlowySvgData get svgData => switch (this) {
        FieldType.RichText => FlowySvgs.field_option_text_xl,
        FieldType.Number => FlowySvgs.field_option_number_xl,
        FieldType.DateTime => FlowySvgs.field_option_date_xl,
        FieldType.SingleSelect => FlowySvgs.field_option_select_xl,
        FieldType.MultiSelect => FlowySvgs.field_option_multiselect_xl,
        FieldType.Checkbox => FlowySvgs.field_option_checkbox_xl,
        FieldType.Checklist => FlowySvgs.field_option_checklist_xl,
        FieldType.URL => FlowySvgs.field_option_url_xl,
        _ => throw UnimplementedError(),
      };

  FlowySvgData get smallSvgData => switch (this) {
        FieldType.RichText => FlowySvgs.field_option_text_s,
        FieldType.Number => FlowySvgs.field_option_number_s,
        FieldType.DateTime => FlowySvgs.field_option_date_s,
        FieldType.SingleSelect => FlowySvgs.field_option_select_s,
        FieldType.MultiSelect => FlowySvgs.field_option_select_s,
        FieldType.Checkbox => FlowySvgs.field_option_checkbox_s,
        FieldType.URL => FlowySvgs.field_option_url_s,
        _ => throw UnimplementedError(),
      };
}

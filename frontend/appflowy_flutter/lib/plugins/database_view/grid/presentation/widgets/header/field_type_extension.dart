import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
  FlowySvgData icon() {
    switch (this) {
      case FieldType.Checkbox:
        return FlowySvgs.checkbox_field_grid;
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return FlowySvgs.date_field_grid;
      case FieldType.MultiSelect:
        return FlowySvgs.multi_select_field_grid;
      case FieldType.Number:
        return FlowySvgs.number_field_grid;
      case FieldType.RichText:
        return FlowySvgs.text_field_grid;
      case FieldType.SingleSelect:
        return FlowySvgs.single_select_field_grid;
      case FieldType.URL:
        return FlowySvgs.url_field_grid;
      case FieldType.Checklist:
        return FlowySvgs.checklist_field_grid;
    }
    throw UnimplementedError;
  }

  String title() {
    switch (this) {
      case FieldType.Checkbox:
        return LocaleKeys.grid_field_checkboxFieldName.tr();
      case FieldType.DateTime:
        return LocaleKeys.grid_field_dateFieldName.tr();
      case FieldType.LastEditedTime:
        return LocaleKeys.grid_field_updatedAtFieldName.tr();
      case FieldType.CreatedTime:
        return LocaleKeys.grid_field_createdAtFieldName.tr();
      case FieldType.MultiSelect:
        return LocaleKeys.grid_field_multiSelectFieldName.tr();
      case FieldType.Number:
        return LocaleKeys.grid_field_numberFieldName.tr();
      case FieldType.RichText:
        return LocaleKeys.grid_field_textFieldName.tr();
      case FieldType.SingleSelect:
        return LocaleKeys.grid_field_singleSelectFieldName.tr();
      case FieldType.URL:
        return LocaleKeys.grid_field_urlFieldName.tr();
      case FieldType.Checklist:
        return LocaleKeys.grid_field_checklistFieldName.tr();
    }
    throw UnimplementedError;
  }
}

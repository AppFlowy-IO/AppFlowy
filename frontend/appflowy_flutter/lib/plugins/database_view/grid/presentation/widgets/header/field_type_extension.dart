import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
  FlowySvgData icon() {
    switch (this) {
      case FieldType.Checkbox:
        return FlowySvgs.checkbox_s;
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return FlowySvgs.date_s;
      case FieldType.MultiSelect:
        return FlowySvgs.multiselect_s;
      case FieldType.Number:
        return FlowySvgs.numbers_s;
      case FieldType.RichText:
        return FlowySvgs.text_s;
      case FieldType.SingleSelect:
        return FlowySvgs.status_s;
      case FieldType.URL:
        return FlowySvgs.attach_s;
      case FieldType.Checklist:
        return FlowySvgs.checklist_s;
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

  bool get canEditHeader => switch (this) {
        FieldType.MultiSelect => true,
        FieldType.SingleSelect => true,
        _ => false,
      };

  bool get canCreateNewGroup => switch (this) {
        FieldType.MultiSelect => true,
        FieldType.SingleSelect => true,
        _ => false,
      };

  bool get canDeleteGroup => switch (this) {
        FieldType.URL ||
        FieldType.SingleSelect ||
        FieldType.MultiSelect ||
        FieldType.DateTime =>
          true,
        _ => false,
      };
}

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
  String iconName() {
    switch (this) {
      case FieldType.Checkbox:
        return "grid/field/checkbox";
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return "grid/field/date";
      case FieldType.MultiSelect:
        return "grid/field/multi_select";
      case FieldType.Number:
        return "grid/field/number";
      case FieldType.RichText:
        return "grid/field/text";
      case FieldType.SingleSelect:
        return "grid/field/single_select";
      case FieldType.URL:
        return "grid/field/url";
      case FieldType.Checklist:
        return "grid/field/checklist";
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

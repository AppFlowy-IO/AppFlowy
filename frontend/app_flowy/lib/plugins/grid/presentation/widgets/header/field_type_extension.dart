import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
  String iconName() {
    switch (this) {
      case FieldType.Checkbox:
        return "grid/field/checkbox";
      case FieldType.DateTime:
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
      case FieldType.CheckList:
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
      case FieldType.CheckList:
        return LocaleKeys.grid_field_checklistFieldName.tr();
    }
    throw UnimplementedError;
  }
}

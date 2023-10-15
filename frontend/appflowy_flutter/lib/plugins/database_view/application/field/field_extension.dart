import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldExtension on FieldPB {
  bool get canBeGroup {
    switch (fieldType) {
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
    if (hasFilter) {
      return false;
    }

    switch (fieldType) {
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
    if (hasSort) {
      return false;
    }

    switch (fieldType) {
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

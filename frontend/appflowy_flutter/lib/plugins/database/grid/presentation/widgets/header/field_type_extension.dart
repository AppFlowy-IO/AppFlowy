import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension FieldTypeListExtension on FieldType {
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

extension RowDetailAccessoryExtension on FieldType {
  bool get showRowDetailAccessory => switch (this) {
        FieldType.Media => false,
        _ => true,
      };
}

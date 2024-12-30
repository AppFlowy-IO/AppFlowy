import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

extension RowDetailAccessoryExtension on FieldType {
  bool get showRowDetailAccessory => switch (this) {
        FieldType.Media => false,
        _ => true,
      };
}

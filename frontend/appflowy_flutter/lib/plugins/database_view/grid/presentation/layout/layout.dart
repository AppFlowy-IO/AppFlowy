import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'sizes.dart';

class GridLayout {
  static double headerWidth(List<FieldPB> fields) {
    if (fields.isEmpty) return 0;

    final fieldsWidth = fields
        .map((field) => field.width.toDouble())
        .reduce((value, element) => value + element);

    return fieldsWidth +
        GridSize.leadingHeaderPadding +
        GridSize.trailHeaderPadding;
  }
}

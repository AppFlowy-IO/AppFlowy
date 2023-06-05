import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'sizes.dart';

class GridLayout {
  static double headerWidth(final List<FieldInfo> fields) {
    if (fields.isEmpty) return 0;

    final fieldsWidth = fields
        .map((final field) => field.width.toDouble())
        .reduce((final value, final element) => value + element);

    return fieldsWidth +
        GridSize.leadingHeaderPadding +
        GridSize.trailHeaderPadding;
  }
}

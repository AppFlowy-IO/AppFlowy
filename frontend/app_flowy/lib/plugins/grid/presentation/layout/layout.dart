import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'sizes.dart';

class GridLayout {
  static double headerWidth(List<GridFieldInfo> fields) {
    if (fields.isEmpty) return 0;

    final fieldsWidth = fields
        .map((field) => field.width.toDouble())
        .reduce((value, element) => value + element);

    return fieldsWidth +
        GridSize.leadingHeaderPadding +
        GridSize.trailHeaderPadding;
  }
}

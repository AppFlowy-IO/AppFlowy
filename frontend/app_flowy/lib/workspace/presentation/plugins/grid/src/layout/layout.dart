import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

import 'sizes.dart';

class GridLayout {
  static double headerWidth(List<Field> fields) {
    if (fields.isEmpty) return 0;

    final fieldsWidth = fields.map((field) => field.width.toDouble()).reduce((value, element) => value + element);

    return fieldsWidth + GridSize.firstHeaderPadding;
  }
}

import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';

import 'grid_sizes.dart';

class GridLayout {
  static double headerWidth(List<FieldOrder> fieldOrders) {
    if (fieldOrders.isEmpty) return 0;

    final fieldsWidth = fieldOrders
        .map(
          (fieldOrder) => fieldOrder.width.toDouble(),
        )
        .reduce((value, element) => value + element);

    return fieldsWidth + GridSize.firstHeaderPadding;
  }
}

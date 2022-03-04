import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'grid_cell.dart';

class GridCellBuilder {
  static GridCellWidget buildCell(Field? field, Cell? cell) {
    if (field == null || cell == null) {
      return const BlankCell();
    }

    switch (field.fieldType) {
      case FieldType.RichText:
        return GridTextCell(cell.content);
      default:
        return const BlankCell();
    }
  }
}

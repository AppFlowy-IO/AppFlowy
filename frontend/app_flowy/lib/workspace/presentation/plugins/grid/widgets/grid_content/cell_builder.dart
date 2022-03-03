import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'grid_cell.dart';

class GridCellBuilder {
  static GridCell buildCell(Field? field, DisplayCell? cell) {
    if (field == null || cell == null) {
      return BlankCell();
    }

    switch (field.fieldType) {
      case FieldType.RichText:
        return GridTextCell(cell.content);
      default:
        return BlankCell();
    }
  }
}

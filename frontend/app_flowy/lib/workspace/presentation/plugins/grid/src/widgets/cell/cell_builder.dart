import 'package:app_flowy/workspace/application/grid/cell/cell_service.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show FieldType;
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell/selection_cell.dart';
import 'text_cell.dart';

GridCellWidget buildGridCellWidget(GridCell gridCell, GridCellCache cellCache, {GridCellStyle? style}) {
  final key = ValueKey(gridCell.rowId + gridCell.field.id);

  final cellContextBuilder = GridCellContextBuilder(gridCell: gridCell, cellCache: cellCache);

  switch (gridCell.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellContextBuilder: cellContextBuilder, key: key);
    case FieldType.DateTime:
      return DateCell(cellContextBuilder: cellContextBuilder, key: key);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellContextBuilder: cellContextBuilder, style: style, key: key);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellContextBuilder: cellContextBuilder, style: style, key: key);
    case FieldType.Number:
      return NumberCell(cellContextBuilder: cellContextBuilder, key: key);
    case FieldType.RichText:
      return GridTextCell(cellContextBuilder: cellContextBuilder, style: style, key: key);

    default:
      throw UnimplementedError;
  }
}

class BlankCell extends StatelessWidget {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

abstract class GridCellWidget extends HoverWidget {
  @override
  final ValueNotifier<bool> onFocus = ValueNotifier<bool>(false);
  GridCellWidget({Key? key}) : super(key: key);
}

abstract class GridCellStyle {}

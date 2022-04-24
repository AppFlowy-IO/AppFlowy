import 'package:app_flowy/workspace/application/grid/cell/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/cell/select_option_service.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show FieldType;
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell/selection_cell.dart';
import 'text_cell.dart';

GridCellWidget buildGridCellWidget(GridCell gridCell, GridCellCache cellCache, {GridCellStyle? style}) {
  final key = ValueKey(gridCell.rowId + gridCell.field.id);

  final cellContext = makeCellContext(gridCell, cellCache);

  switch (gridCell.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellContext: cellContext, key: key);
    case FieldType.DateTime:
      return DateCell(cellContext: cellContext, key: key);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellContext: cellContext as GridSelectOptionCellContext, style: style, key: key);
    case FieldType.Number:
      return NumberCell(cellContext: cellContext, key: key);
    case FieldType.RichText:
      return GridTextCell(cellContext: cellContext, style: style, key: key);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellContext: cellContext as GridSelectOptionCellContext, style: style, key: key);
    default:
      throw UnimplementedError;
  }
}

GridCellContext makeCellContext(GridCell gridCell, GridCellCache cellCache) {
  switch (gridCell.field.fieldType) {
    case FieldType.Checkbox:
    case FieldType.DateTime:
    case FieldType.Number:
    case FieldType.RichText:
      return GridDefaultCellContext(
        gridCell: gridCell,
        cellCache: cellCache,
        cellDataLoader: DefaultCellDataLoader(gridCell: gridCell),
      );
    case FieldType.MultiSelect:
    case FieldType.SingleSelect:
      return GridSelectOptionCellContext(
        gridCell: gridCell,
        cellCache: cellCache,
        cellDataLoader: SelectOptionCellDataLoader(gridCell: gridCell),
      );
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

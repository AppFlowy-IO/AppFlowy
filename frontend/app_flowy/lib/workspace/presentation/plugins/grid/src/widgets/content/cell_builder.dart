import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell.dart';
import 'text_cell.dart';

Widget buildGridCell(CellContext cellContext) {
  switch (cellContext.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellContext: cellContext);
    case FieldType.DateTime:
      return DateCell(cellContext: cellContext);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellContext: cellContext);
    case FieldType.Number:
      return NumberCell(cellContext: cellContext);
    case FieldType.RichText:
      return GridTextCell(cellContext: cellContext);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellContext: cellContext);
    default:
      return const BlankCell();
  }
}

class BlankCell extends StatelessWidget {
  const BlankCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

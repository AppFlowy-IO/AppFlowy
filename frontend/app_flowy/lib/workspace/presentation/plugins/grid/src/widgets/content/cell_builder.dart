import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell.dart';
import 'text_cell.dart';

Widget buildGridCell(GridCellData cellData) {
  switch (cellData.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellData: cellData);
    case FieldType.DateTime:
      return DateCell(cellData: cellData);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellContext: cellData);
    case FieldType.Number:
      return NumberCell(cellData: cellData);
    case FieldType.RichText:
      return GridTextCell(cellData: cellData);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellContext: cellData);
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

import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell.dart';
import 'text_cell.dart';

Widget buildGridCell(Field field, Cell? cell) {
  switch (field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(field: field, cell: cell);
    case FieldType.DateTime:
      return DateCell(field: field, cell: cell);
    case FieldType.MultiSelect:
      return MultiSelectCell(field: field, cell: cell);
    case FieldType.Number:
      return NumberCell(field: field, cell: cell);
    case FieldType.RichText:
      return GridTextCell(field: field, cell: cell);
    case FieldType.SingleSelect:
      return SingleSelectCell(field: field, cell: cell);
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

import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell.dart';
import 'text_cell.dart';

Widget buildGridCell(String rowId, Field field, FutureCellData cellData) {
  if (cellData == null) {
    return const SizedBox();
  }
  final key = ValueKey(field.id + rowId);
  switch (field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellData: cellData, key: key);
    case FieldType.DateTime:
      return DateCell(cellData: cellData, key: key);
    case FieldType.MultiSelect:
      return MultiSelectCell(cellData: cellData, key: key);
    case FieldType.Number:
      return NumberCell(cellData: cellData, key: key);
    case FieldType.RichText:
      return GridTextCell(cellData: cellData, key: key);
    case FieldType.SingleSelect:
      return SingleSelectCell(cellData: cellData, key: key);
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

import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/widgets.dart';
import 'checkbox_cell.dart';
import 'date_cell.dart';
import 'number_cell.dart';
import 'selection_cell.dart';
import 'text_cell.dart';

Widget buildGridCell(FieldType fieldType, FutureCellData cellData) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxCell(cellData: cellData, key: ObjectKey(cellData));
    case FieldType.DateTime:
      return DateCell(cellData: cellData, key: ObjectKey(cellData));
    case FieldType.MultiSelect:
      return MultiSelectCell(cellData: cellData, key: ObjectKey(cellData));
    case FieldType.Number:
      return NumberCell(cellData: cellData, key: ObjectKey(cellData));
    case FieldType.RichText:
      return GridTextCell(cellData: cellData, key: ObjectKey(cellData));
    case FieldType.SingleSelect:
      return SingleSelectCell(cellData: cellData, key: ObjectKey(cellData));
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

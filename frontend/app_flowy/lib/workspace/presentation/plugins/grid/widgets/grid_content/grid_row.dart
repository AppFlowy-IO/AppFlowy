import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/grid_sizes.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flutter/material.dart';
import 'cell_builder.dart';
import 'cell_container.dart';
import 'grid_row_leading.dart';

class GridRowContext {
  final RepeatedFieldOrder fieldOrders;
  final Map<String, Field> fieldById;
  final Map<String, DisplayCell> cellByFieldId;
  GridRowContext(this.fieldOrders, this.fieldById, this.cellByFieldId);
}

class GridRow extends StatelessWidget {
  final RowInfo rowInfo;
  final Function(bool)? onHoverChange;
  const GridRow(this.rowInfo, {Key? key, this.onHoverChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.rowHeight,
      child: _buildRowBody(),
    );
  }

  Widget _buildRowBody() {
    Widget rowWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildCells(),
    );

    if (onHoverChange != null) {
      rowWidget = MouseRegion(
        onEnter: (event) => onHoverChange!(true),
        onExit: (event) => onHoverChange!(false),
        cursor: MouseCursor.uncontrolled,
        child: rowWidget,
      );
    }

    return rowWidget;
  }

  List<Widget> _buildCells() {
    var cells = List<Widget>.empty(growable: true);
    cells.add(const RowLeading());

    rowInfo.fieldOrders.where((element) => element.visibility).forEach((fieldOrder) {
      final field = rowInfo.fieldMap[fieldOrder.fieldId];
      final data = rowInfo.displayCellMap[fieldOrder.fieldId];

      final cell = CellContainer(
        width: fieldOrder.width.toDouble(),
        child: GridCellBuilder.buildCell(field, data),
      );

      cells.add(cell);
    });
    return cells;
  }
}

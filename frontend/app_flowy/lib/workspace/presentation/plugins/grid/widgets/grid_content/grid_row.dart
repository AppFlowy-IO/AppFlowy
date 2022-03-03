import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/grid_sizes.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter/material.dart';
import 'cell_builder.dart';
import 'cell_container.dart';
import 'grid_cell.dart';

class GridRowContext {
  final RepeatedFieldOrder fieldOrders;
  final Map<String, Field> fieldById;
  final Map<String, GridCell> cellByFieldId;
  GridRowContext(this.fieldOrders, this.fieldById, this.cellByFieldId);
}

class GridRowWidget extends StatelessWidget {
  final RowInfo rowInfo;
  final Function(bool)? onHoverChange;
  const GridRowWidget(this.rowInfo, {Key? key, this.onHoverChange}) : super(key: key);

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

    for (var field in rowInfo.fields) {
      final data = rowInfo.cellMap[field.id];
      final cell = CellContainer(
        width: field.width.toDouble(),
        child: GridCellBuilder.buildCell(field, data),
      );

      cells.add(cell);
    }
    return cells;
  }
}

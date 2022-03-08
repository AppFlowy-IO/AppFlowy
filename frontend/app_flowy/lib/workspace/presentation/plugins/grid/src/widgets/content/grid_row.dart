import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cell_builder.dart';
import 'cell_container.dart';
import 'grid_cell.dart';
import 'package:dartz/dartz.dart';

class GridRowWidget extends StatelessWidget {
  final GridRowData data;
  final Function(bool)? onHoverChange;
  const GridRowWidget(this.data, {Key? key, this.onHoverChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<RowBloc>(param1: data),
      child: BlocBuilder<RowBloc, RowState>(
        builder: (context, state) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (p) => context.read<RowBloc>().add(RowEvent.highlightRow(some(data.row.id))),
              onExit: (p) => context.read<RowBloc>().add(RowEvent.highlightRow(none())),
              child: SizedBox(
                height: data.row.height.toDouble(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildCells(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCells() {
    return [
      SizedBox(width: GridSize.startHeaderPadding, child: RowLeading(rowId: data.row.id)),
      ...data.fields.map(
        (field) {
          final cellData = data.cellMap[field.id];
          return CellContainer(
            width: field.width.toDouble(),
            child: GridCellBuilder.buildCell(field, cellData),
          );
        },
      )
    ].toList();
  }
}

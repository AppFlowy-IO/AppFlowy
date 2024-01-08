import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_timestamp_cell.dart';
import '../desktop_row_detail/desktop_row_detail_timestamp_cell.dart';
import '../mobile_grid/mobile_grid_timestamp_cell.dart';
import '../mobile_row_detail/mobile_row_detail_timestamp_cell.dart';

abstract class IEditableTimestampCellSkin {
  const IEditableTimestampCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimestampCellBloc bloc,
    TimestampCellState state,
  );

  factory IEditableTimestampCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridTimestampCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailTimestampCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridTimestampCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailTimestampCellSkin(),
    };
  }
}

class EditableTimestampCell extends EditableCellWidget {
  final TimestampCellController cellController;
  final IEditableTimestampCellSkin skin;

  EditableTimestampCell({
    super.key,
    required this.cellController,
    required this.skin,
  });

  @override
  GridCellState<EditableTimestampCell> createState() => _TimestampCellState();
}

class _TimestampCellState extends GridCellState<EditableTimestampCell> {
  TimestampCellBloc get cellBloc => context.read<TimestampCellBloc>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        return TimestampCellBloc(cellController: widget.cellController)
          ..add(const TimestampCellEvent.initial());
      },
      child: BlocBuilder<TimestampCellBloc, TimestampCellState>(
        builder: (context, state) {
          return widget.skin.build(
            context,
            widget.cellContainerNotifier,
            cellBloc,
            state,
          );
        },
      ),
    );
  }

  @override
  void requestBeginFocus() {
    widget.cellContainerNotifier.isFocus = true;
  }

  @override
  String? onCopy() => cellBloc.state.dateStr;
}

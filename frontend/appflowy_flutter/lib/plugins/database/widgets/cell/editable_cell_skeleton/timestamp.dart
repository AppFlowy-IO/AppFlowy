import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/timestamp_cell/timestamp_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
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
  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableTimestampCellSkin skin;

  final FieldType fieldType;

  EditableTimestampCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
    required this.fieldType,
  });

  @override
  GridCellState<EditableTimestampCell> createState() => _TimestampCellState();
}

class _TimestampCellState extends GridCellState<EditableTimestampCell> {
  late final cellBloc = TimestampCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  )..add(const TimestampCellEvent.initial());

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
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

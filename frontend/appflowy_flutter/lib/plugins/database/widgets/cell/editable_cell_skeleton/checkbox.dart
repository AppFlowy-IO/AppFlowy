import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checkbox_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_checkbox_cell.dart';
import '../desktop_row_detail/desktop_row_detail_checkbox_cell.dart';
import '../mobile_grid/mobile_grid_checkbox_cell.dart';
import '../mobile_row_detail/mobile_row_detail_checkbox_cell.dart';

abstract class IEditableCheckboxCellSkin {
  const IEditableCheckboxCellSkin();

  factory IEditableCheckboxCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridCheckboxCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailCheckboxCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridCheckboxCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailCheckboxCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    CheckboxCellBloc bloc,
    CheckboxCellState state,
  );
}

class EditableCheckboxCell extends EditableCellWidget {
  EditableCheckboxCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableCheckboxCellSkin skin;

  @override
  GridCellState<EditableCheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends GridCellState<EditableCheckboxCell> {
  late final cellBloc = CheckboxCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  )..add(const CheckboxCellEvent.initial());

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
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
  void onRequestFocus() => cellBloc.add(const CheckboxCellEvent.select());

  @override
  String? onCopy() {
    if (cellBloc.state.isSelected) {
      return "Yes";
    } else {
      return "No";
    }
  }
}

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../desktop_grid/desktop_grid_checklist_cell.dart';
import '../desktop_row_detail/desktop_row_detail_checklist_cell.dart';
import '../mobile_grid/mobile_grid_checklist_cell.dart';
import '../mobile_row_detail/mobile_row_detail_checklist_cell.dart';

abstract class IEditableChecklistCellSkin {
  const IEditableChecklistCellSkin();

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    ChecklistCellState state,
    PopoverController popoverController,
  );

  factory IEditableChecklistCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridChecklistCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailChecklistCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridChecklistCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailChecklistCellSkin(),
    };
  }
}

class EditableChecklistCell extends EditableCellWidget {
  final ChecklistCellController cellController;
  final IEditableChecklistCellSkin skin;

  EditableChecklistCell({
    super.key,
    required this.cellController,
    required this.skin,
  });

  @override
  GridCellState<EditableChecklistCell> createState() =>
      GridChecklistCellState();
}

class GridChecklistCellState extends GridCellState<EditableChecklistCell> {
  final PopoverController _popover = PopoverController();

  late final cellBloc = ChecklistCellBloc(cellController: widget.cellController)
    ..add(const ChecklistCellEvent.initial());

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          return widget.skin.build(
            context,
            widget.cellContainerNotifier,
            cellBloc,
            state,
            _popover,
          );
        },
      ),
    );
  }

  @override
  void requestBeginFocus() {
    if (widget.skin is DesktopGridChecklistCellSkin) {
      _popover.show();
    }
  }
}

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cell_builder.dart';
import 'checklist_cell_bloc.dart';
import 'checklist_cell_editor.dart';
import 'checklist_progress_bar.dart';

class GridChecklistCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  GridChecklistCell({required this.cellControllerBuilder, Key? key})
      : super(key: key);

  @override
  GridCellState<GridChecklistCell> createState() => GridChecklistCellState();
}

class GridChecklistCellState extends GridCellState<GridChecklistCell> {
  late ChecklistCardCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCardCellBloc(cellController: cellController);
    _cellBloc.add(const ChecklistCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: AppFlowyPopover(
        controller: _popover,
        constraints: BoxConstraints.loose(const Size(260, 400)),
        direction: PopoverDirection.bottomWithLeftAligned,
        triggerActions: PopoverTriggerFlags.none,
        popupBuilder: (BuildContext context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCellEditing.value = true;
          });
          return GridChecklistCellEditor(
            cellController:
                widget.cellControllerBuilder.build() as ChecklistCellController,
          );
        },
        onClose: () => widget.onCellEditing.value = false,
        child: Padding(
          padding: GridSize.cellContentInsets,
          child: BlocBuilder<ChecklistCardCellBloc, ChecklistCellState>(
            builder: (context, state) =>
                ChecklistProgressBar(percent: state.percent),
          ),
        ),
      ),
    );
  }

  @override
  void requestBeginFocus() => _popover.show();
}

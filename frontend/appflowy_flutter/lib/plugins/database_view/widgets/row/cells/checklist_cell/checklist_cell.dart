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

class ChecklistCellStyle extends GridCellStyle {
  String placeholder;
  EdgeInsets? cellPadding;

  ChecklistCellStyle({
    required this.placeholder,
    this.cellPadding,
  });
}

class GridChecklistCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final ChecklistCellStyle? cellStyle;
  GridChecklistCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    super.key,
  }) {
    cellStyle = style as ChecklistCellStyle?;
  }

  @override
  GridCellState<GridChecklistCell> createState() => GridChecklistCellState();
}

class GridChecklistCellState extends GridCellState<GridChecklistCell> {
  late ChecklistCellBloc _cellBloc;
  late final PopoverController _popover;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as ChecklistCellController;
    _cellBloc = ChecklistCellBloc(cellController: cellController);
    _cellBloc.add(const ChecklistCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: AppFlowyPopover(
        margin: EdgeInsets.zero,
        controller: _popover,
        constraints: BoxConstraints.loose(const Size(360, 400)),
        direction: PopoverDirection.bottomWithLeftAligned,
        triggerActions: PopoverTriggerFlags.none,
        popupBuilder: (BuildContext context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCellFocus.value = true;
          });
          return GridChecklistCellEditor(
            cellController:
                widget.cellControllerBuilder.build() as ChecklistCellController,
          );
        },
        onClose: () => widget.onCellFocus.value = false,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding:
                widget.cellStyle?.cellPadding ?? GridSize.cellContentInsets,
            child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
              builder: (context, state) {
                if (state.allOptions.isEmpty) {
                  return FlowyText.medium(
                    widget.cellStyle?.placeholder ?? "",
                    color: Theme.of(context).hintColor,
                  );
                }
                return ChecklistProgressBar(percent: state.percent);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void requestBeginFocus() => _popover.show();
}

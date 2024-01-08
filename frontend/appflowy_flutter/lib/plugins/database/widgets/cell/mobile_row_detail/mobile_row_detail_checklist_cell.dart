import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/mobile_checklist_cell_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/checklist.dart';

class MobileRowDetailChecklistCellSkin extends IEditableChecklistSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    ChecklistCellState state,
    PopoverController popoverController,
  ) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: () => showMobileBottomSheet(
        context,
        padding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.background,
        builder: (context) {
          return MobileChecklistCellEditScreen(
            cellController: bloc.cellController,
          );
        },
      ),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 48,
          minWidth: double.infinity,
        ),
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(14)),
        ),
        child: Padding(
          padding: widget.cellStyle.cellPadding ?? EdgeInsets.zero,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: state.tasks.isEmpty
                ? FlowyText(
                    widget.cellStyle.placeholder,
                    fontSize: 15,
                    color: Theme.of(context).hintColor,
                  )
                : ChecklistProgressBar(
                    tasks: state.tasks,
                    percent: state.percent,
                    fontSize: 15,
                  ),
          ),
        ),
      ),
    );
  }
}

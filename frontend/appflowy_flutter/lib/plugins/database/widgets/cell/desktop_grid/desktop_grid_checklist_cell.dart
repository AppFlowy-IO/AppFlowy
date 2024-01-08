import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/checklist_cell/checklist_progress_bar.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/checklist.dart';

class DesktopGridChecklistCellSkin extends IEditableChecklistSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    ChecklistCellState state,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      margin: EdgeInsets.zero,
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(360, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (BuildContext popoverContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cellContainerNotifier.isFocus = true;
        });
        return GridChecklistCellEditor(
          cellController: bloc.cellController,
        );
      },
      onClose: () => cellContainerNotifier.isFocus = false,
      child: state.tasks.isEmpty
          ? const SizedBox.shrink()
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: GridSize.cellContentInsets,
                child: ChecklistProgressBar(
                  tasks: state.tasks,
                  percent: state.percent,
                ),
              ),
            ),
    );
  }
}

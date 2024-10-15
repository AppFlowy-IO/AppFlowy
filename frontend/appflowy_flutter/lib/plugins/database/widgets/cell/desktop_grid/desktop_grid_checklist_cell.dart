import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/checklist.dart';

class DesktopGridChecklistCellSkin extends IEditableChecklistCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      margin: EdgeInsets.zero,
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(360, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      skipTraversal: true,
      popupBuilder: (popoverContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          cellContainerNotifier.isFocus = true;
        });
        return BlocProvider.value(
          value: bloc,
          child: ChecklistCellEditor(
            cellController: bloc.cellController,
          ),
        );
      },
      onClose: () => cellContainerNotifier.isFocus = false,
      child: BlocBuilder<ChecklistCellBloc, ChecklistCellState>(
        builder: (context, state) {
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: GridSize.cellContentInsets,
            child: state.tasks.isEmpty
                ? const SizedBox.shrink()
                : ChecklistProgressBar(
                    tasks: state.tasks,
                    percent: state.percent,
                  ),
          );
        },
      ),
    );
  }
}

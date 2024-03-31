import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_checklist_cell_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/checklist.dart';

class MobileGridChecklistCellSkin extends IEditableChecklistCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ChecklistCellBloc bloc,
    ChecklistCellState state,
    PopoverController popoverController,
  ) {
    return FlowyButton(
      radius: BorderRadius.zero,
      hoverColor: Colors.transparent,
      text: Container(
        alignment: Alignment.centerLeft,
        padding: GridSize.cellContentInsets,
        child: state.tasks.isEmpty
            ? const SizedBox.shrink()
            : ChecklistProgressBar(
                tasks: state.tasks,
                percent: state.percent,
                textStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 15),
              ),
      ),
      onTap: () => showMobileBottomSheet(
        context,
        builder: (context) {
          return BlocProvider.value(
            value: bloc,
            child: const MobileChecklistCellEditScreen(),
          );
        },
      ),
    );
  }
}

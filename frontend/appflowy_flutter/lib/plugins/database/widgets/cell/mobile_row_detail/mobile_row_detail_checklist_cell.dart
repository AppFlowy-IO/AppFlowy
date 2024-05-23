import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checklist_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/checklist.dart';

class MobileRowDetailChecklistCellSkin extends IEditableChecklistCellSkin {
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
        backgroundColor: AFThemeExtension.of(context).background,
        builder: (context) {
          return BlocProvider.value(
            value: bloc,
            child: const MobileChecklistCellEditScreen(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        alignment: AlignmentDirectional.centerStart,
        child: state.tasks.isEmpty
            ? FlowyText(
                LocaleKeys.grid_row_textPlaceholder.tr(),
                fontSize: 15,
                color: Theme.of(context).hintColor,
              )
            : ChecklistProgressBar(
                tasks: state.tasks,
                percent: state.percent,
                textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: Theme.of(context).hintColor,
                    ),
              ),
      ),
    );
  }
}

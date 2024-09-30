import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/date_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

import '../editable_cell_skeleton/date.dart';

class DesktopGridDateCellSkin extends IEditableDateCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    DateCellBloc bloc,
    DateCellState state,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      controller: popoverController,
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(260, 620)),
      margin: EdgeInsets.zero,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: state.fieldInfo.wrapCellContent ?? false
            ? _buildCellContent(state)
            : SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: _buildCellContent(state),
              ),
      ),
      popupBuilder: (BuildContext popoverContent) {
        return DateCellEditor(
          cellController: bloc.cellController,
          onDismissed: () => cellContainerNotifier.isFocus = false,
        );
      },
      onClose: () {
        cellContainerNotifier.isFocus = false;
      },
    );
  }

  Widget _buildCellContent(DateCellState state) {
    final wrap = state.fieldInfo.wrapCellContent ?? false;
    return Padding(
      padding: GridSize.cellContentInsets,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FlowyText(
              state.dateStr,
              overflow: wrap ? null : TextOverflow.ellipsis,
              maxLines: wrap ? null : 1,
            ),
          ),
          if (state.data?.reminderId.isNotEmpty ?? false) ...[
            const HSpace(4),
            FlowyTooltip(
              message: LocaleKeys.grid_field_reminderOnDateTooltip.tr(),
              child: const FlowySvg(FlowySvgs.clock_alarm_s),
            ),
          ],
        ],
      ),
    );
  }
}

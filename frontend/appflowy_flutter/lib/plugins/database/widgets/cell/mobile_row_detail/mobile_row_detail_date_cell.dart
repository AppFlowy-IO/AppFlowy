import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/date_picker/mobile_date_picker_screen.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/date.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileRowDetailDateCellSkin extends IEditableDateCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    DateCellBloc bloc,
    DateCellState state,
    PopoverController popoverController,
  ) {
    final dateStr = getDateCellStrFromCellData(
      state.fieldInfo,
      state.cellData,
    );
    final text =
        dateStr.isEmpty ? LocaleKeys.grid_row_textPlaceholder.tr() : dateStr;
    final color = dateStr.isEmpty ? Theme.of(context).hintColor : null;

    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: () => showMobileBottomSheet(
        context,
        builder: (context) {
          return MobileDateCellEditScreen(
            controller: bloc.cellController,
            showAsFullScreen: false,
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
        child: Row(
          children: [
            if (state.cellData.reminderId.isNotEmpty) ...[
              const FlowySvg(FlowySvgs.clock_alarm_s),
              const HSpace(6),
            ],
            FlowyText.regular(
              text,
              fontSize: 16,
              color: color,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}

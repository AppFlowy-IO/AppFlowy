import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/time_cell_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

import '../editable_cell_skeleton/time.dart';

class DesktopRowDetailTimeCellSkin extends IEditableTimeCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimeCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      margin: EdgeInsets.zero,
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(360, 400)),
      direction: PopoverDirection.bottomWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      skipTraversal: true,
      popupBuilder: (BuildContext popoverContext) {
        return BlocProvider.value(
          value: bloc,
          child: TimeCellEditor(cellController: bloc.cellController),
        );
      },
      onClose: () => cellContainerNotifier.isFocus = false,
      child: TextField(
        controller: textEditingController,
        focusNode: focusNode,
        readOnly: bloc.state.timeType != TimeTypePB.PlainTime,
        onEditingComplete: () => focusNode.unfocus(),
        onSubmitted: (_) {
          focusNode.unfocus();
        },
        onTap: () {
          if (bloc.state.timeType != TimeTypePB.PlainTime) {
            popoverController.show();
          }
        },
        maxLines: bloc.state.wrap ? null : 1,
        style: Theme.of(context).textTheme.bodyMedium,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: LocaleKeys.grid_row_textPlaceholder.tr(),
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
          isDense: true,
        ),
      ),
    );
  }
}

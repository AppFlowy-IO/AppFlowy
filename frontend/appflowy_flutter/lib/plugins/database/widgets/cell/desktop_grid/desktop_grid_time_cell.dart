import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/time_cell_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import '../editable_cell_skeleton/time.dart';

class DesktopGridTimeCellSkin extends IEditableTimeCellSkin {
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
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextField(
          controller: textEditingController,
          readOnly: context.watch<TimeCellBloc>().state.timeType !=
              TimeTypePB.PlainTime,
          onTap: () {
            if (context.read<TimeCellBloc>().state.timeType !=
                TimeTypePB.PlainTime) {
              popoverController.show();
            }
          },
          focusNode: focusNode,
          onEditingComplete: () => focusNode.unfocus(),
          onSubmitted: (_)  {
focusNode.unfocus();
          },
          maxLines: context.watch<TimeCellBloc>().state.wrap ? null : 1,
          style: Theme.of(context).textTheme.bodyMedium,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            contentPadding: GridSize.cellContentInsets,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/time_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

import '../editable_cell_skeleton/time.dart';

class MobileRowDetailTimeCellSkin extends IEditableTimeCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimeCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    PopoverController popoverController,
  ) {
    final timeCellState = bloc.state;

    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
      decoration: InputDecoration(
        enabledBorder:
            _getInputBorder(color: Theme.of(context).colorScheme.outline),
        focusedBorder:
            _getInputBorder(color: Theme.of(context).colorScheme.primary),
        hintText: LocaleKeys.grid_row_textPlaceholder.tr(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        isCollapsed: true,
        isDense: true,
        constraints: const BoxConstraints(),
      ),
      // close keyboard when tapping outside of the text field
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      readOnly: timeCellState.timeType != TimeTypePB.PlainTime,
    );
  }

  InputBorder _getInputBorder({Color? color}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color!),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      gapPadding: 0,
    );
  }
}

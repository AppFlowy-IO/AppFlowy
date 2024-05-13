import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/timer_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/timer.dart';

class MobileRowDetailTimerCellSkin extends IEditableTimerCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimerCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
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

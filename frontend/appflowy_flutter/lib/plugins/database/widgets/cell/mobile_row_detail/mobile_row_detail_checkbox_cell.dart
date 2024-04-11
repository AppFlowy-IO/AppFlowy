import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/checkbox.dart';

class MobileRowDetailCheckboxCellSkin extends IEditableCheckboxCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    CheckboxCellBloc bloc,
    CheckboxCellState state,
  ) {
    return InkWell(
      onTap: () => bloc.add(const CheckboxCellEvent.select()),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
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
        child: FlowySvg(
          state.isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
          color: Theme.of(context).colorScheme.onBackground,
          blendMode: BlendMode.dst,
          size: const Size.square(24),
        ),
      ),
    );
  }
}

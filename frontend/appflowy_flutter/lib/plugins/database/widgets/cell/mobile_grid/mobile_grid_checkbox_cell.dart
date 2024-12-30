import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checkbox_cell_bloc.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/checkbox.dart';

class MobileGridCheckboxCellSkin extends IEditableCheckboxCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    CheckboxCellBloc bloc,
    CheckboxCellState state,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: FlowySvg(
          state.isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
          blendMode: BlendMode.dst,
          size: const Size.square(24),
        ),
      ),
    );
  }
}

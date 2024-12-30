import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/checkbox_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/checkbox.dart';

class DesktopRowDetailCheckboxCellSkin extends IEditableCheckboxCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    CheckboxCellBloc bloc,
    CheckboxCellState state,
  ) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: FlowyIconButton(
        hoverColor: Colors.transparent,
        onPressed: () => bloc.add(const CheckboxCellEvent.select()),
        icon: FlowySvg(
          state.isSelected ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
          blendMode: BlendMode.dst,
          size: const Size.square(20),
        ),
        width: 20,
      ),
    );
  }
}

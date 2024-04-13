import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/timestamp_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';

import '../editable_cell_skeleton/timestamp.dart';

class DesktopGridTimestampCellSkin extends IEditableTimestampCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimestampCellBloc bloc,
    TimestampCellState state,
  ) {
    return Container(
      alignment: AlignmentDirectional.centerStart,
      child: state.wrap
          ? _buildCellContent(state)
          : SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: _buildCellContent(state),
            ),
    );
  }

  Widget _buildCellContent(TimestampCellState state) {
    return Padding(
      padding: GridSize.cellContentInsets,
      child: FlowyText.medium(
        state.dateStr,
        overflow: state.wrap ? null : TextOverflow.ellipsis,
        maxLines: state.wrap ? null : 1,
      ),
    );
  }
}

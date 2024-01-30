import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/timestamp_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/timestamp.dart';

class MobileGridTimestampCellSkin extends IEditableTimestampCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TimestampCellBloc bloc,
    TimestampCellState state,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: FlowyText(
        state.dateStr,
        fontSize: 15,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

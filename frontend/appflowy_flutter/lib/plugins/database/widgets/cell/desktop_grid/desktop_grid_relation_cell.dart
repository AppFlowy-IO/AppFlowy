import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/relation_cell/relation_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/relation_cell/relation_cell_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/relation.dart';

class DesktopGridRelationCellSkin extends IEditableRelationCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    RelationCellBloc bloc,
    RelationCellState state,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
      margin: EdgeInsets.zero,
      onClose: () => cellContainerNotifier.isFocus = false,
      popupBuilder: (context) {
        return BlocProvider.value(
          value: bloc,
          child: RelationCellEditor(
            selectedRowIds: state.rows.map((row) => row.rowId).toList(),
            databaseId: state.relatedDatabaseId,
            onSelectRow: (rowId) {
              bloc.add(RelationCellEvent.selectRow(rowId));
            },
          ),
        );
      },
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: GridSize.cellContentInsets,
        child: Wrap(
          runSpacing: 4.0,
          spacing: 4.0,
          children: state.rows
              .map(
                (row) => FlowyText.medium(
                  row.name,
                  decoration: TextDecoration.underline,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

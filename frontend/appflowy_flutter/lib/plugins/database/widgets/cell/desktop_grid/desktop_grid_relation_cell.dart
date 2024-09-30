import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/relation_cell_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
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
          child: const RelationCellEditor(),
        );
      },
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: state.wrap
            ? _buildWrapRows(context, state.rows)
            : _buildNoWrapRows(context, state.rows),
      ),
    );
  }

  Widget _buildWrapRows(
    BuildContext context,
    List<RelatedRowDataPB> rows,
  ) {
    return Padding(
      padding: GridSize.cellContentInsets,
      child: Wrap(
        runSpacing: 4,
        spacing: 4.0,
        children: rows.map(
          (row) {
            final isEmpty = row.name.isEmpty;
            return FlowyText(
              isEmpty ? LocaleKeys.grid_row_titlePlaceholder.tr() : row.name,
              color: isEmpty ? Theme.of(context).hintColor : null,
              decoration: TextDecoration.underline,
              overflow: TextOverflow.ellipsis,
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildNoWrapRows(
    BuildContext context,
    List<RelatedRowDataPB> rows,
  ) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: GridSize.cellContentInsets,
        child: SeparatedRow(
          separatorBuilder: () => const HSpace(4.0),
          mainAxisSize: MainAxisSize.min,
          children: rows.map(
            (row) {
              final isEmpty = row.name.isEmpty;
              return FlowyText(
                isEmpty ? LocaleKeys.grid_row_titlePlaceholder.tr() : row.name,
                color: isEmpty ? Theme.of(context).hintColor : null,
                decoration: TextDecoration.underline,
                overflow: TextOverflow.ellipsis,
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

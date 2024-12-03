import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/relation_cell_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/relation.dart';

class DesktopRowDetailRelationCellSkin extends IEditableRelationCellSkin {
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
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: state.rows.isEmpty
            ? _buildPlaceholder(context)
            : _buildRows(context, state.rows),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return FlowyText(
      LocaleKeys.grid_row_textPlaceholder.tr(),
      color: Theme.of(context).hintColor,
    );
  }

  Widget _buildRows(BuildContext context, List<RelatedRowDataPB> rows) {
    return Wrap(
      runSpacing: 4.0,
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
    );
  }
}

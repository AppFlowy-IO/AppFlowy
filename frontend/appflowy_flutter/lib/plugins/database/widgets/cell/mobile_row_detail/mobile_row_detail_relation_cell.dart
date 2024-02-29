import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/relation.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileRowDetailRelationCellSkin extends IEditableRelationCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    RelationCellBloc bloc,
    RelationCellState state,
    PopoverController popoverController,
  ) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      onTap: () => showMobileBottomSheet(
        context,
        padding: EdgeInsets.zero,
        builder: (context) {
          return const FlowyText("Coming soon");
        },
      ),
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
        child: Wrap(
          runSpacing: 4.0,
          spacing: 4.0,
          children: state.rows
              .map(
                (row) => FlowyText(
                  row.name,
                  fontSize: 16,
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

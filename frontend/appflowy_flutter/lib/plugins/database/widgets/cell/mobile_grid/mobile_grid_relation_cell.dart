import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/relation_cell_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/relation.dart';

class MobileGridRelationCellSkin extends IEditableRelationCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    RelationCellBloc bloc,
    RelationCellState state,
    PopoverController popoverController,
  ) {
    return FlowyButton(
      radius: BorderRadius.zero,
      hoverColor: Colors.transparent,
      margin: EdgeInsets.zero,
      text: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: state.rows
                .map(
                  (row) => FlowyText(
                    row.name,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                )
                .toList(),
          ),
        ),
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          builder: (context) {
            return const FlowyText("Coming soon");
          },
        );
      },
    );
  }
}

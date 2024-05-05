import 'package:appflowy/plugins/database/application/cell/bloc/summary_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/summary.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:flutter/material.dart';

class MobileRowDetailSummaryCellSkin extends IEditableSummaryCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SummaryCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return Column(
      children: [
        TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onEditingComplete: () => focusNode.unfocus(),
          onSubmitted: (_) => focusNode.unfocus(),
          style: Theme.of(context).textTheme.bodyMedium,
          textInputAction: TextInputAction.done,
          maxLines: null,
          minLines: 1,
          decoration: InputDecoration(
            contentPadding: GridSize.cellContentInsets,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
          ),
        ),
        Row(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SummaryCellAccessory(
                viewId: bloc.cellController.viewId,
                fieldId: bloc.cellController.fieldId,
                rowId: bloc.cellController.rowId,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowActionList extends StatelessWidget {
  final RowController rowController;
  const RowActionList({
    required this.rowController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RowActionSheetBloc>(
      create: (context) => RowActionSheetBloc(
        viewId: rowController.viewId,
        rowId: rowController.rowId,
        groupId: rowController.groupId,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RowDetailPageDuplicateButton(
              rowId: rowController.rowId,
              groupId: rowController.groupId,
            ),
            const VSpace(4.0),
            RowDetailPageDeleteButton(rowId: rowController.rowId),
          ],
        ),
      ),
    );
  }
}

class RowDetailPageDeleteButton extends StatelessWidget {
  final String rowId;
  const RowDetailPageDeleteButton({required this.rowId, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_delete.tr()),
        leftIcon: const FlowySvg(FlowySvgs.trash_m),
        onTap: () {
          context
              .read<RowActionSheetBloc>()
              .add(const RowActionSheetEvent.deleteRow());
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class RowDetailPageDuplicateButton extends StatelessWidget {
  final String rowId;
  final String? groupId;
  const RowDetailPageDuplicateButton({
    required this.rowId,
    this.groupId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_duplicate.tr()),
        leftIcon: const FlowySvg(FlowySvgs.copy_s),
        onTap: () {
          context
              .read<RowActionSheetBloc>()
              .add(const RowActionSheetEvent.duplicateRow());
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

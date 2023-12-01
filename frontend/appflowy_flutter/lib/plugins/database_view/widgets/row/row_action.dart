import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class RowActionList extends StatelessWidget {
  final RowController rowController;
  const RowActionList({
    required this.rowController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RowDetailPageDuplicateButton(
            viewId: rowController.viewId,
            rowId: rowController.rowId,
            groupId: rowController.groupId,
          ),
          const VSpace(4.0),
          RowDetailPageDeleteButton(
            viewId: rowController.viewId,
            rowId: rowController.rowId,
          ),
        ],
      ),
    );
  }
}

class RowDetailPageDeleteButton extends StatelessWidget {
  const RowDetailPageDeleteButton({
    super.key,
    required this.viewId,
    required this.rowId,
  });

  final String viewId;
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_delete.tr()),
        leftIcon: const FlowySvg(FlowySvgs.trash_m),
        onTap: () {
          RowBackendService.deleteRow(viewId, rowId);
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class RowDetailPageDuplicateButton extends StatelessWidget {
  final String viewId;
  final String rowId;
  final String? groupId;
  const RowDetailPageDuplicateButton({
    super.key,
    required this.viewId,
    required this.rowId,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_duplicate.tr()),
        leftIcon: const FlowySvg(FlowySvgs.copy_s),
        onTap: () {
          RowBackendService.duplicateRow(viewId, rowId, groupId);
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

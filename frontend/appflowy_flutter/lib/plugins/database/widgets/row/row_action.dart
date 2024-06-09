import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class RowActionList extends StatelessWidget {
  const RowActionList({super.key, required this.rowController});

  final RowController rowController;

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
          RowBackendService.deleteRows(viewId, [rowId]);
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class RowDetailPageDuplicateButton extends StatelessWidget {
  const RowDetailPageDuplicateButton({
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
        text: FlowyText.regular(LocaleKeys.grid_row_duplicate.tr()),
        leftIcon: const FlowySvg(FlowySvgs.copy_s),
        onTap: () {
          RowBackendService.duplicateRow(viewId, rowId);
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

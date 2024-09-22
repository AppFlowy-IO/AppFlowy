import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/domain/sort_service.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowActionMenu extends StatelessWidget {
  const RowActionMenu({
    super.key,
    required this.viewId,
    required this.rowId,
    this.actions = RowAction.values,
    this.groupId,
  });

  const RowActionMenu.board({
    super.key,
    required this.viewId,
    required this.rowId,
    required this.groupId,
  }) : actions = const [RowAction.duplicate, RowAction.delete];

  final String viewId;
  final RowId rowId;
  final List<RowAction> actions;
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    final cells =
        actions.map((action) => _actionCell(context, action)).toList();

    return SeparatedColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => VSpace(GridSize.typeOptionSeparatorHeight),
      children: cells,
    );
  }

  Widget _actionCell(BuildContext context, RowAction action) {
    Widget icon = FlowySvg(action.icon);
    if (action == RowAction.insertAbove) {
      icon = RotatedBox(quarterTurns: 1, child: icon);
    }
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(
          action.text,
          overflow: TextOverflow.ellipsis,
          lineHeight: 1.0,
        ),
        onTap: () {
          action.performAction(context, viewId, rowId);
          PopoverContainer.of(context).close();
        },
        leftIcon: icon,
      ),
    );
  }
}

enum RowAction {
  insertAbove,
  insertBelow,
  duplicate,
  delete;

  FlowySvgData get icon {
    return switch (this) {
      insertAbove => FlowySvgs.arrow_s,
      insertBelow => FlowySvgs.add_s,
      duplicate => FlowySvgs.duplicate_s,
      delete => FlowySvgs.delete_s,
    };
  }

  String get text {
    return switch (this) {
      insertAbove => LocaleKeys.grid_row_insertRecordAbove.tr(),
      insertBelow => LocaleKeys.grid_row_insertRecordBelow.tr(),
      duplicate => LocaleKeys.grid_row_duplicate.tr(),
      delete => LocaleKeys.grid_row_delete.tr(),
    };
  }

  void performAction(BuildContext context, String viewId, String rowId) {
    switch (this) {
      case insertAbove:
      case insertBelow:
        final position = this == insertAbove
            ? OrderObjectPositionTypePB.Before
            : OrderObjectPositionTypePB.After;
        final intention = this == insertAbove
            ? LocaleKeys.grid_row_createRowAboveDescription.tr()
            : LocaleKeys.grid_row_createRowBelowDescription.tr();
        if (context.read<GridBloc>().state.sorts.isNotEmpty) {
          showCancelAndDeleteDialog(
            context: context,
            title: LocaleKeys.grid_sort_sortsActive.tr(
              namedArgs: {'intention': intention},
            ),
            description: LocaleKeys.grid_sort_removeSorting.tr(),
            confirmLabel: LocaleKeys.button_remove.tr(),
            closeOnAction: true,
            onDelete: () {
              SortBackendService(viewId: viewId).deleteAllSorts();
              RowBackendService.createRow(
                viewId: viewId,
                position: position,
                targetRowId: rowId,
              );
            },
          );
        } else {
          RowBackendService.createRow(
            viewId: viewId,
            position: position,
            targetRowId: rowId,
          );
        }
        break;
      case duplicate:
        RowBackendService.duplicateRow(viewId, rowId);
        break;
      case delete:
        showConfirmDeletionDialog(
          context: context,
          name: LocaleKeys.grid_row_label.tr(),
          description: LocaleKeys.grid_row_deleteRowPrompt.tr(),
          onConfirm: () => RowBackendService.deleteRows(viewId, [rowId]),
        );
        break;
    }
  }
}

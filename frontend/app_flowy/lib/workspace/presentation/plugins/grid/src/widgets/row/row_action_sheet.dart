import 'package:app_flowy/workspace/application/grid/row/row_action_sheet_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridRowActionSheet extends StatelessWidget {
  final RowData rowData;
  const GridRowActionSheet({required this.rowData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RowActionSheetBloc(rowData: rowData),
      child: BlocBuilder<RowActionSheetBloc, RowActionSheetState>(
        builder: (context, state) {
          final cells = _RowAction.values
              .map(
                (action) => _RowActionCell(
                  action: action,
                  onDismissed: () => remove(context),
                ),
              )
              .toList();

          //
          final list = ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: cells.length,
            separatorBuilder: (context, index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
            physics: StyledScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return cells[index];
            },
          );
          return list;
        },
      ),
    );
  }

  void show(BuildContext overlayContext) {
    FlowyOverlay.of(overlayContext).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(140, 200)),
      ),
      identifier: GridRowActionSheet.identifier(),
      anchorContext: overlayContext,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
    );
  }

  void remove(BuildContext overlayContext) {
    FlowyOverlay.of(overlayContext).remove(GridRowActionSheet.identifier());
  }

  static String identifier() {
    return (GridRowActionSheet).toString();
  }
}

class _RowActionCell extends StatelessWidget {
  final _RowAction action;
  final VoidCallback onDismissed;
  const _RowActionCell({required this.action, required this.onDismissed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(action.title(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () {
          action.performAction(context);
          onDismissed();
        },
        leftIcon: svgWidget(action.iconName(), color: theme.iconColor),
      ),
    );
  }
}

enum _RowAction {
  delete,
  duplicate,
}

extension _RowActionExtension on _RowAction {
  String iconName() {
    switch (this) {
      case _RowAction.duplicate:
        return 'grid/duplicate';
      case _RowAction.delete:
        return 'grid/delete';
    }
  }

  String title() {
    switch (this) {
      case _RowAction.duplicate:
        return LocaleKeys.grid_row_duplicate.tr();
      case _RowAction.delete:
        return LocaleKeys.grid_row_delete.tr();
    }
  }

  void performAction(BuildContext context) {
    switch (this) {
      case _RowAction.duplicate:
        // context.read<RowActionSheetBloc>().add(const RowActionSheetEvent.duplicateRow());
        break;
      case _RowAction.delete:
        // context.read<RowActionSheetBloc>().add(const RowActionSheetEvent.deleteRow());
        break;
    }
  }
}

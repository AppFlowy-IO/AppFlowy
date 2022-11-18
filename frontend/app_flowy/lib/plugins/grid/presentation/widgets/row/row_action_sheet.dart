import 'package:app_flowy/plugins/grid/application/row/row_action_sheet_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/row/row_cache.dart';
import '../../layout/sizes.dart';

class GridRowActionSheet extends StatelessWidget {
  final RowInfo rowData;
  const GridRowActionSheet({required this.rowData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RowActionSheetBloc(rowInfo: rowData),
      child: BlocBuilder<RowActionSheetBloc, RowActionSheetState>(
        builder: (context, state) {
          final cells = _RowAction.values
              .where((value) => value.enable())
              .map(
                (action) => _RowActionCell(action: action),
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
}

class _RowActionCell extends StatelessWidget {
  final _RowAction action;
  const _RowActionCell({required this.action, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(
          action.title(),
          fontSize: 12,
          color: action.enable() ? null : Theme.of(context).disabledColor,
        ),
        onTap: () {
          if (action.enable()) {
            action.performAction(context);
          }
        },
        leftIcon: svgWidget(
          action.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
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

  bool enable() {
    switch (this) {
      case _RowAction.duplicate:
        return false;
      case _RowAction.delete:
        return true;
    }
  }

  void performAction(BuildContext context) {
    switch (this) {
      case _RowAction.duplicate:
        context
            .read<RowActionSheetBloc>()
            .add(const RowActionSheetEvent.duplicateRow());
        break;
      case _RowAction.delete:
        context
            .read<RowActionSheetBloc>()
            .add(const RowActionSheetEvent.deleteRow());

        break;
    }
  }
}

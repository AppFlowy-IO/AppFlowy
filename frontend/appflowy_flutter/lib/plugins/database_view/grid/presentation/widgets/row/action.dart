import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_action_sheet_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';

class RowActions extends StatelessWidget {
  final RowInfo rowData;
  const RowActions({required this.rowData, final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => RowActionSheetBloc(rowInfo: rowData),
      child: BlocBuilder<RowActionSheetBloc, RowActionSheetState>(
        builder: (final context, final state) {
          final cells = _RowAction.values
              .where((final value) => value.enable())
              .map((final action) => _ActionCell(action: action))
              .toList();

          //
          final list = ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: cells.length,
            separatorBuilder: (final context, final index) {
              return VSpace(GridSize.typeOptionSeparatorHeight);
            },
            physics: StyledScrollPhysics(),
            itemBuilder: (final BuildContext context, final int index) {
              return cells[index];
            },
          );
          return list;
        },
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  final _RowAction action;
  const _ActionCell({required this.action, final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          action.title(),
          color: action.enable()
              ? AFThemeExtension.of(context).textColor
              : Theme.of(context).disabledColor,
        ),
        onTap: () {
          if (action.enable()) {
            action.performAction(context);
          }
        },
        leftIcon: svgWidget(
          action.iconName(),
          color: Theme.of(context).iconTheme.color,
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

  void performAction(final BuildContext context) {
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

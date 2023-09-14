import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_action_sheet_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../layout/sizes.dart';

class RowActions extends StatelessWidget {
  final String viewId;
  final RowId rowId;
  final String? groupId;
  const RowActions({
    required this.viewId,
    required this.rowId,
    this.groupId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RowActionSheetBloc(
        viewId: viewId,
        rowId: rowId,
        groupId: groupId,
      ),
      child: BlocBuilder<RowActionSheetBloc, RowActionSheetState>(
        builder: (context, state) {
          final cells = _RowAction.values
              .where((value) => value.enable())
              .map((action) => _ActionCell(action: action))
              .toList();

          return ListView.separated(
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
        },
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  final _RowAction action;
  const _ActionCell({required this.action, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        useIntrinsicWidth: true,
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
        leftIcon: FlowySvg(
          action.icon(),
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
  FlowySvgData icon() {
    switch (this) {
      case _RowAction.duplicate:
        return FlowySvgs.copy_s;
      case _RowAction.delete:
        return FlowySvgs.delete_s;
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

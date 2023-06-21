import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import '../../grid/presentation/layout/sizes.dart';
import 'setting_button.dart';

class DatabaseSettingList extends StatelessWidget {
  final DatabaseController databaseContoller;
  final Function(DatabaseSettingAction, DatabaseController) onAction;
  const DatabaseSettingList({
    required this.databaseContoller,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = actionsForDatabaseLayout(databaseContoller.databaseLayout)
        .map((action) {
      return DatabaseSettingItem(
        action: action,
        onAction: (action) => onAction(action, databaseContoller),
      );
    }).toList();

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
  }
}

class DatabaseSettingItem extends StatelessWidget {
  final DatabaseSettingAction action;
  final Function(DatabaseSettingAction) onAction;

  const DatabaseSettingItem({
    required this.action,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        text: FlowyText.medium(
          action.title(),
          color: AFThemeExtension.of(context).textColor,
        ),
        onTap: () => onAction(action),
        leftIcon: svgWidget(
          action.iconName(),
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}

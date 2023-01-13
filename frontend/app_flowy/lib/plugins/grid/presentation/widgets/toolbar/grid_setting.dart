import 'package:app_flowy/plugins/grid/application/setting/setting_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import '../../../application/field/field_controller.dart';
import '../../layout/sizes.dart';

class GridSettingContext {
  final String gridId;
  final GridFieldController fieldController;

  GridSettingContext({
    required this.gridId,
    required this.fieldController,
  });
}

class GridSettingList extends StatelessWidget {
  final GridSettingContext settingContext;
  final Function(GridSettingAction, GridSettingContext) onAction;
  const GridSettingList(
      {required this.settingContext, required this.onAction, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells =
        GridSettingAction.values.where((value) => value.enable()).map((action) {
      return _SettingItem(
          action: action,
          onAction: (action) => onAction(action, settingContext));
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
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
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final GridSettingAction action;
  final Function(GridSettingAction) onAction;

  const _SettingItem({
    required this.action,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(
          action.title(),
          color: action.enable() ? null : Theme.of(context).disabledColor,
        ),
        onTap: () => onAction(action),
        leftIcon: svgWidget(
          action.iconName(),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

extension _GridSettingExtension on GridSettingAction {
  String iconName() {
    switch (this) {
      case GridSettingAction.showFilters:
        return 'grid/setting/filter';
      case GridSettingAction.sortBy:
        return 'grid/setting/sort';
      case GridSettingAction.showProperties:
        return 'grid/setting/properties';
    }
  }

  String title() {
    switch (this) {
      case GridSettingAction.showFilters:
        return LocaleKeys.grid_settings_filter.tr();
      case GridSettingAction.sortBy:
        return LocaleKeys.grid_settings_sortBy.tr();
      case GridSettingAction.showProperties:
        return LocaleKeys.grid_settings_Properties.tr();
    }
  }

  bool enable() {
    switch (this) {
      case GridSettingAction.showProperties:
        return true;
      default:
        return false;
    }
  }
}

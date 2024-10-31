import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/setting/database_layout_selector.dart';
import 'package:appflowy/plugins/database/widgets/group/database_group.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_property_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum DatabaseSettingAction {
  showProperties,
  showLayout,
  showGroup,
  showCalendarLayout,
}

extension DatabaseSettingActionExtension on DatabaseSettingAction {
  FlowySvgData iconData() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return FlowySvgs.multiselect_s;
      case DatabaseSettingAction.showLayout:
        return FlowySvgs.database_layout_m;
      case DatabaseSettingAction.showGroup:
        return FlowySvgs.group_s;
      case DatabaseSettingAction.showCalendarLayout:
        return FlowySvgs.calendar_layout_m;
    }
  }

  String title() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return LocaleKeys.grid_settings_properties.tr();
      case DatabaseSettingAction.showLayout:
        return LocaleKeys.grid_settings_databaseLayout.tr();
      case DatabaseSettingAction.showGroup:
        return LocaleKeys.grid_settings_group.tr();
      case DatabaseSettingAction.showCalendarLayout:
        return LocaleKeys.calendar_settings_name.tr();
    }
  }

  Widget build(
    BuildContext context,
    DatabaseController databaseController,
    PopoverMutex popoverMutex,
  ) {
    final popover = switch (this) {
      DatabaseSettingAction.showLayout => DatabaseLayoutSelector(
          viewId: databaseController.viewId,
          currentLayout: databaseController.databaseLayout,
        ),
      DatabaseSettingAction.showGroup => DatabaseGroupList(
          viewId: databaseController.viewId,
          databaseController: databaseController,
          onDismissed: () {},
        ),
      DatabaseSettingAction.showProperties => DatabasePropertyList(
          viewId: databaseController.viewId,
          fieldController: databaseController.fieldController,
        ),
      DatabaseSettingAction.showCalendarLayout => CalendarLayoutSetting(
          databaseController: databaseController,
        ),
    };

    return AppFlowyPopover(
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      direction: PopoverDirection.leftWithTopAligned,
      mutex: popoverMutex,
      margin: EdgeInsets.zero,
      offset: const Offset(-14, 0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          text: FlowyText(
            title(),
            lineHeight: 1.0,
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIcon: FlowySvg(
            iconData(),
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
      popupBuilder: (context) => popover,
    );
  }
}

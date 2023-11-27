import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_item_widget.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_paginated_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/database_layout_selector.dart';
import 'package:appflowy/plugins/database_view/widgets/group/database_group.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/mobile_calendar_settings.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_property_list.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
        return FlowySvgs.properties_s;
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
          viewId: databaseController.viewId,
          fieldController: databaseController.fieldController,
          calendarSettingController: ICalendarSettingImpl(
            databaseController,
          ),
        ),
    };

    return AppFlowyPopover(
      triggerActions: PlatformExtension.isMobile
          ? PopoverTriggerFlags.none
          : PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      direction: PopoverDirection.leftWithTopAligned,
      mutex: popoverMutex,
      margin: EdgeInsets.zero,
      offset: const Offset(-14, 0),
      child: PlatformExtension.isMobile
          ? MobileSettingItem(
              name: title(),
              trailing: _trailingFromSetting(
                context,
                databaseController.databaseLayout,
              ),
              leadingIcon: FlowySvg(
                iconData(),
                size: const Size.square(18),
                color: Theme.of(context).iconTheme.color,
              ),
              onTap: _actionFromSetting(context, databaseController),
            )
          : SizedBox(
              height: GridSize.popoverItemHeight,
              child: FlowyButton(
                onTap: null,
                hoverColor: AFThemeExtension.of(context).lightGreyHover,
                text: FlowyText.medium(
                  title(),
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

  VoidCallback? _actionFromSetting(
    BuildContext context,
    DatabaseController databaseController,
  ) =>
      switch (this) {
        DatabaseSettingAction.showLayout => () =>
            _showLayoutSettings(context, databaseController),
        DatabaseSettingAction.showProperties => () =>
            _showPropertiesSettings(context, databaseController),
        DatabaseSettingAction.showCalendarLayout => () =>
            _showCalendarSettings(context, databaseController),
        // Group Settings
        _ => null,
      };

  void _showLayoutSettings(
    BuildContext context,
    DatabaseController databaseController,
  ) =>
      FlowyBottomSheetController.of(context)!.push(
        SheetPage(
          title: LocaleKeys.settings_mobile_selectLayout.tr(),
          body: DatabaseLayoutSelector(
            viewId: databaseController.viewId,
            currentLayout: databaseController.databaseLayout,
          ),
        ),
      );

  void _showPropertiesSettings(
    BuildContext context,
    DatabaseController databaseController,
  ) =>
      FlowyBottomSheetController.of(context)!.push(
        SheetPage(
          title: LocaleKeys.grid_settings_properties.tr(),
          body: DatabasePropertyList(
            viewId: databaseController.viewId,
            fieldController: databaseController.fieldController,
          ),
        ),
      );

  void _showCalendarSettings(
    BuildContext context,
    DatabaseController databaseController,
  ) =>
      FlowyBottomSheetController.of(context)!.push(
        SheetPage(
          title: LocaleKeys.calendar_settings_name.tr(),
          body: MobileCalendarLayoutSetting(
            viewId: databaseController.viewId,
            fieldController: databaseController.fieldController,
            calendarSettingController: ICalendarSettingImpl(
              databaseController,
            ),
          ),
        ),
      );

  Widget? _trailingFromSetting(BuildContext context, DatabaseLayoutPB layout) =>
      switch (this) {
        DatabaseSettingAction.showLayout => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowyText(
                layout.name,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        _ => null,
      };
}

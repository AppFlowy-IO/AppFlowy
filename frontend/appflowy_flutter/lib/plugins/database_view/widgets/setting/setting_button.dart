import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database_view/widgets/group/database_group.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/toolbar/grid_layout.dart';
import 'setting_property_list.dart';

class SettingButton extends StatefulWidget {
  final DatabaseController databaseController;
  const SettingButton({
    required this.databaseController,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingButton> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: _popoverController,
      constraints: BoxConstraints.loose(const Size(200, 400)),
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 8),
      triggerActions: PopoverTriggerFlags.none,
      child: FlowyTextButton(
        LocaleKeys.settings_title.tr(),
        fontColor: AFThemeExtension.of(context).textColor,
        fontSize: FontSizes.s11,
        fontWeight: FontWeight.w400,
        fillColor: Colors.transparent,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        padding: GridSize.toolbarSettingButtonInsets,
        radius: Corners.s4Border,
        onPressed: () => _popoverController.show(),
      ),
      popupBuilder: (BuildContext context) {
        return DatabaseSettingListPopover(
          databaseController: widget.databaseController,
        );
      },
    );
  }
}

class DatabaseSettingListPopover extends StatefulWidget {
  final DatabaseController databaseController;

  const DatabaseSettingListPopover({
    required this.databaseController,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DatabaseSettingListPopoverState();
}

class _DatabaseSettingListPopoverState
    extends State<DatabaseSettingListPopover> {
  late final PopoverMutex popoverMutex;

  @override
  void initState() {
    super.initState();
    popoverMutex = PopoverMutex();
  }

  @override
  Widget build(BuildContext context) {
    final cells =
        actionsForDatabaseLayout(widget.databaseController.databaseLayout)
            .map(
              (action) => action.build(
                context,
                widget.databaseController,
                popoverMutex,
              ),
            )
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
  }
}

class ICalendarSettingImpl extends ICalendarSetting {
  final DatabaseController _databaseController;

  ICalendarSettingImpl(this._databaseController);

  @override
  void updateLayoutSettings(CalendarLayoutSettingPB layoutSettings) {
    _databaseController.updateLayoutSetting(layoutSettings);
  }

  @override
  CalendarLayoutSettingPB? getLayoutSetting() {
    return _databaseController.databaseLayoutSetting?.calendar;
  }
}

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
      DatabaseSettingAction.showLayout => DatabaseLayoutList(
          viewId: databaseController.viewId,
          currentLayout: databaseController.databaseLayout,
        ),
      DatabaseSettingAction.showGroup => DatabaseGroupList(
          viewId: databaseController.viewId,
          fieldController: databaseController.fieldController,
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
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      direction: PopoverDirection.leftWithTopAligned,
      mutex: popoverMutex,
      margin: EdgeInsets.zero,
      offset: const Offset(-16, 0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
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
}

/// Returns the list of actions that should be shown for the given database layout.
List<DatabaseSettingAction> actionsForDatabaseLayout(DatabaseLayoutPB? layout) {
  switch (layout) {
    case DatabaseLayoutPB.Board:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        DatabaseSettingAction.showGroup,
      ];
    case DatabaseLayoutPB.Calendar:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
        DatabaseSettingAction.showCalendarLayout,
      ];
    case DatabaseLayoutPB.Grid:
      return [
        DatabaseSettingAction.showProperties,
        DatabaseSettingAction.showLayout,
      ];
    default:
      return [];
  }
}

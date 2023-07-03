import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database_view/widgets/group/database_group.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../grid/presentation/widgets/toolbar/grid_layout.dart';
import '../field/grid_property.dart';
import 'database_setting.dart';

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
  late PopoverController _popoverController;

  @override
  void initState() {
    _popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: AppFlowyPopover(
        controller: _popoverController,
        constraints: BoxConstraints.loose(const Size(200, 400)),
        direction: PopoverDirection.bottomWithLeftAligned,
        offset: const Offset(0, 8),
        margin: EdgeInsets.zero,
        triggerActions: PopoverTriggerFlags.none,
        child: FlowyTextButton(
          LocaleKeys.settings_title.tr(),
          fontColor: AFThemeExtension.of(context).textColor,
          fillColor: Colors.transparent,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          padding: GridSize.typeOptionContentInsets,
          onPressed: () => _popoverController.show(),
        ),
        popupBuilder: (BuildContext context) {
          return _DatabaseSettingListPopover(
            databaseController: widget.databaseController,
          );
        },
      ),
    );
  }
}

class _DatabaseSettingListPopover extends StatefulWidget {
  final DatabaseController databaseController;

  const _DatabaseSettingListPopover({
    required this.databaseController,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DatabaseSettingListPopoverState();
}

class _DatabaseSettingListPopoverState
    extends State<_DatabaseSettingListPopover> {
  DatabaseSettingAction? _action;

  @override
  Widget build(BuildContext context) {
    if (_action == null) {
      return DatabaseSettingList(
        databaseContoller: widget.databaseController,
        onAction: (action, settingContext) {
          setState(() {
            _action = action;
          });
        },
      ).padding(all: 6.0);
    } else {
      switch (_action!) {
        case DatabaseSettingAction.showLayout:
          return DatabaseLayoutList(
            viewId: widget.databaseController.viewId,
            currentLayout: widget.databaseController.databaseLayout,
          );
        case DatabaseSettingAction.showGroup:
          return DatabaseGroupList(
            viewId: widget.databaseController.viewId,
            fieldController: widget.databaseController.fieldController,
            onDismissed: () {
              // widget.popoverController.close();
            },
          );
        case DatabaseSettingAction.showProperties:
          return DatabasePropertyList(
            viewId: widget.databaseController.viewId,
            fieldController: widget.databaseController.fieldController,
          );
        case DatabaseSettingAction.showCalendarLayout:
          return CalendarLayoutSetting(
            viewId: widget.databaseController.viewId,
            fieldController: widget.databaseController.fieldController,
            calendarSettingController: ICalendarSettingImpl(
              widget.databaseController,
            ),
          );
      }
    }
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
  String iconName() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return 'grid/setting/properties';
      case DatabaseSettingAction.showLayout:
        return 'grid/setting/database_layout';
      case DatabaseSettingAction.showGroup:
        return 'grid/setting/group';
      case DatabaseSettingAction.showCalendarLayout:
        return 'grid/setting/calendar_layout';
    }
  }

  String title() {
    switch (this) {
      case DatabaseSettingAction.showProperties:
        return LocaleKeys.grid_settings_Properties.tr();
      case DatabaseSettingAction.showLayout:
        return LocaleKeys.grid_settings_databaseLayout.tr();
      case DatabaseSettingAction.showGroup:
        return LocaleKeys.grid_settings_group.tr();
      case DatabaseSettingAction.showCalendarLayout:
        return LocaleKeys.calendar_settings_name.tr();
    }
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

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/database_settings_list.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingButton extends StatefulWidget {
  const SettingButton({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

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
        onPressed: _popoverController.show,
      ),
      popupBuilder: (BuildContext context) => DatabaseSettingsList(
        databaseController: widget.databaseController,
      ),
    );
  }
}

class ICalendarSettingImpl extends ICalendarSetting {
  const ICalendarSettingImpl(this._databaseController);

  final DatabaseController _databaseController;

  @override
  void updateLayoutSettings(CalendarLayoutSettingPB layoutSettings) =>
      _databaseController.updateLayoutSetting(
        calendarLayoutSetting: layoutSettings,
      );

  @override
  CalendarLayoutSettingPB? getLayoutSetting() =>
      _databaseController.databaseLayoutSetting?.calendar;
}

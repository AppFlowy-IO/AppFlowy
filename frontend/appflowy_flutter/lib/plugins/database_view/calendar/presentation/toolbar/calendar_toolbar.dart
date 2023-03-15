import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/calendar_bloc.dart';
import 'calendar_setting.dart';

class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _SettingButton(),
        ],
      ),
    );
  }
}

class _SettingButton extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingButtonState();
}

class _SettingButtonState extends State<_SettingButton> {
  late PopoverController popoverController;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithRightAligned,
      triggerActions: PopoverTriggerFlags.none,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      margin: EdgeInsets.zero,
      child: FlowyTextButton(
        LocaleKeys.settings_title.tr(),
        fillColor: Colors.transparent,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        padding: GridSize.typeOptionContentInsets,
        onPressed: () => popoverController.show(),
      ),
      popupBuilder: (BuildContext popoverContext) {
        final bloc = context.watch<CalendarBloc>();
        final settingContext = CalendarSettingContext(
          viewId: bloc.viewId,
          fieldController: bloc.fieldController,
        );
        return CalendarSetting(
          settingContext: settingContext,
          layoutSettings: bloc.state.settings.fold(
            () => null,
            (settings) => settings,
          ),
          onUpdated: (layoutSettings) {
            if (layoutSettings == null) {
              return;
            }
            context
                .read<CalendarBloc>()
                .add(CalendarEvent.updateCalendarLayoutSetting(layoutSettings));
          },
        );
      }, // use blocbuilder
    );
  }
}

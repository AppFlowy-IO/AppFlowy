import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'calendar_layout_setting.dart';

/// The highest-level widget shown in the popover triggered by clicking the
/// "Settings" button. Shows [AllCalendarSettings] by default, but replaces its
/// contents with the submenu when a category is selected.
class CalendarSetting extends StatelessWidget {
  final CalendarSettingContext settingContext;
  final CalendarLayoutSettingsPB? layoutSettings;
  final Function(CalendarLayoutSettingsPB? layoutSettings) onUpdated;

  const CalendarSetting({
    required this.onUpdated,
    required this.layoutSettings,
    required this.settingContext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarSettingBloc>(
      create: (context) => CalendarSettingBloc(layoutSettings: layoutSettings),
      child: BlocBuilder<CalendarSettingBloc, CalendarSettingState>(
        builder: (context, state) {
          final CalendarSettingAction? action =
              state.selectedAction.foldLeft(null, (previous, action) => action);
          switch (action) {
            case CalendarSettingAction.layout:
              return CalendarLayoutSetting(
                onUpdated: onUpdated,
                settingContext: settingContext,
              );
            default:
              return const AllCalendarSettings().padding(all: 6.0);
          }
        },
      ),
    );
  }
}

/// Shows all of the available categories of settings that can be set here.
/// For now, this only includes the Layout category.
class AllCalendarSettings extends StatelessWidget {
  const AllCalendarSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final items = CalendarSettingAction.values
        .map((e) => _settingItem(context, e))
        .toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            VSpace(GridSize.typeOptionSeparatorHeight),
        physics: StyledScrollPhysics(),
        itemBuilder: (BuildContext context, int index) => items[index],
      ),
    );
  }

  Widget _settingItem(BuildContext context, CalendarSettingAction action) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(action.title()),
        onTap: () {
          context
              .read<CalendarSettingBloc>()
              .add(CalendarSettingEvent.performAction(action));
        },
      ),
    );
  }
}

extension _SettingExtension on CalendarSettingAction {
  String title() {
    switch (this) {
      case CalendarSettingAction.layout:
        return LocaleKeys.grid_settings_layout.tr();
    }
  }
}

class CalendarSettingContext {
  final String viewId;
  final FieldController fieldController;

  CalendarSettingContext({
    required this.viewId,
    required this.fieldController,
  });
}

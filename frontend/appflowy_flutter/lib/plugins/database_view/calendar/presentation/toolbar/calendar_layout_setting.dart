import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart'
    hide DateFormat;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:styled_widget/styled_widget.dart';

class CalendarLayoutSetting extends StatelessWidget {
  final Function(CalendarLayoutSettingsPB? layoutSettings) onUpdated;

  const CalendarLayoutSetting({
    required this.onUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarSettingBloc, CalendarSettingState>(
      builder: (context, state) {
        final CalendarLayoutSettingsPB? settings = state.layoutSetting
            .foldLeft(null, (previous, settings) => settings);

        if (settings == null) {
          return const CircularProgressIndicator();
        }
        final availableSettings = _availableCalendarSettings(settings);

        final items = availableSettings.map((setting) {
          switch (setting) {
            case CalendarLayoutSettingAction.showWeekNumber:
              return ShowWeekNumber(
                showWeekNumbers: settings.showWeekNumbers,
                onUpdated: (showWeekNumbers) {
                  _updateLayoutSettings(context,
                      onUpdated: onUpdated, showWeekNumbers: showWeekNumbers);
                },
              );
            case CalendarLayoutSettingAction.showWeekends:
              return ShowWeekends(
                showWeekends: settings.showWeekends,
                onUpdated: (showWeekends) {
                  _updateLayoutSettings(context,
                      onUpdated: onUpdated, showWeekends: showWeekends);
                },
              );
            case CalendarLayoutSettingAction.firstDayOfWeek:
              return FirstDayOfWeek(
                firstDayOfWeek: settings.firstDayOfWeek,
                onUpdated: (firstDayOfWeek) {
                  _updateLayoutSettings(context,
                      onUpdated: onUpdated, firstDayOfWeek: firstDayOfWeek);
                },
              );
            default:
              return ShowWeekends(
                showWeekends: settings.showWeekends,
                onUpdated: (showWeekends) {
                  _updateLayoutSettings(context,
                      onUpdated: onUpdated, showWeekends: showWeekends);
                },
              );
          }
        }).toList();

        return SizedBox(
          width: 200,
          child: ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            physics: StyledScrollPhysics(),
            itemBuilder: (BuildContext context, int index) => items[index],
            padding: const EdgeInsets.all(6.0),
          ),
        );
      },
    );
  }

  List<CalendarLayoutSettingAction> _availableCalendarSettings(
      CalendarLayoutSettingsPB layoutSettings) {
    List<CalendarLayoutSettingAction> settings = [
      // CalendarLayoutSettingAction.layoutField,
      // CalendarLayoutSettingAction.layoutType,
      // CalendarLayoutSettingAction.showWeekNumber,
    ];

    switch (layoutSettings.layoutTy) {
      case CalendarLayoutPB.DayLayout:
        // settings.add(CalendarLayoutSettingAction.showTimeLine);
        break;
      case CalendarLayoutPB.MonthLayout:
        settings.addAll([
          // CalendarLayoutSettingAction.showWeekends,
          // if (layoutSettings.showWeekends)
          CalendarLayoutSettingAction.firstDayOfWeek,
        ]);
        break;
      case CalendarLayoutPB.WeekLayout:
        settings.addAll([
          // CalendarLayoutSettingAction.showWeekends,
          // if (layoutSettings.showWeekends)
          CalendarLayoutSettingAction.firstDayOfWeek,
          // CalendarLayoutSettingAction.showTimeLine,
        ]);
        break;
    }

    return settings;
  }

  void _updateLayoutSettings(
    BuildContext context, {
    required Function(CalendarLayoutSettingsPB? layoutSettings) onUpdated,
    bool? showWeekends,
    bool? showWeekNumbers,
    int? firstDayOfWeek,
  }) {
    CalendarLayoutSettingsPB setting = context
        .read<CalendarSettingBloc>()
        .state
        .layoutSetting
        .foldLeft(null, (previous, settings) => settings)!;
    setting.freeze();
    setting = setting.rebuild((setting) {
      if (showWeekends != null) {
        setting.showWeekends = !showWeekends;
      }
      if (showWeekNumbers != null) {
        setting.showWeekNumbers = !showWeekNumbers;
      }
      if (firstDayOfWeek != null) {
        setting.firstDayOfWeek = firstDayOfWeek;
      }
    });
    context
        .read<CalendarSettingBloc>()
        .add(CalendarSettingEvent.updateLayoutSetting(setting));
    onUpdated(setting);
  }
}

class ShowWeekNumber extends StatelessWidget {
  final bool showWeekNumbers;
  final Function(bool showWeekNumbers) onUpdated;

  const ShowWeekNumber(
      {super.key, required this.showWeekNumbers, required this.onUpdated});

  @override
  Widget build(BuildContext context) {
    return _toggleItem(
      onToggle: (showWeekNumbers) {
        onUpdated(!showWeekNumbers);
      },
      value: showWeekNumbers,
      text: "Show week numbers",
    );
  }
}

class ShowWeekends extends StatelessWidget {
  final bool showWeekends;
  final Function(bool showWeekends) onUpdated;
  const ShowWeekends({
    super.key,
    required this.showWeekends,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return _toggleItem(
      onToggle: (showWeekends) {
        onUpdated(!showWeekends);
      },
      value: showWeekends,
      text: "Show weekends",
    );
  }
}

class FirstDayOfWeek extends StatelessWidget {
  final int firstDayOfWeek;
  final Function(int firstDayOfWeek) onUpdated;
  const FirstDayOfWeek({
    super.key,
    required this.firstDayOfWeek,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      popupBuilder: (context) {
        final symbols =
            DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
        // starts from sunday
        final items = symbols.WEEKDAYS.asMap().entries.map((entry) {
          final index = (entry.key - 1) % 7;
          final string = entry.value;
          return SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyButton(
              text: FlowyText.medium(string),
              onTap: () => onUpdated(index),
            ),
          );
        }).toList();

        return SizedBox(
          width: 100,
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, index) => items[index],
            separatorBuilder: (context, index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            itemCount: 2,
          ),
        );
      },
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: const FlowyButton(
          margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
          text: FlowyText.medium("First day of week"),
        ),
      ),
    );
  }
}

Widget _toggleItem({
  required String text,
  required bool value,
  required void Function(bool) onToggle,
}) {
  return SizedBox(
    height: GridSize.popoverItemHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
      child: Row(
        children: [
          FlowyText.medium(text),
          const Spacer(),
          Toggle(
            value: value,
            onChanged: (value) => onToggle(!value),
            style: ToggleStyle.big,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    ),
  );
}

enum CalendarLayoutSettingAction {
  layoutField,
  layoutType,
  showWeekends,
  firstDayOfWeek,
  showWeekNumber,
  showTimeLine,
}

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart';

abstract class ICalendarSetting {
  const ICalendarSetting();

  /// Returns the current layout settings for the calendar view.
  CalendarLayoutSettingPB? getLayoutSetting();

  /// Updates the layout settings for the calendar view.
  void updateLayoutSettings(CalendarLayoutSettingPB layoutSettings);
}

/// Widget that displays a list of settings that alters the appearance of the
/// calendar
class CalendarLayoutSetting extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  final ICalendarSetting calendarSettingController;

  const CalendarLayoutSetting({
    required this.viewId,
    required this.fieldController,
    required this.calendarSettingController,
    super.key,
  });

  @override
  State<CalendarLayoutSetting> createState() => _CalendarLayoutSettingState();
}

class _CalendarLayoutSettingState extends State<CalendarLayoutSetting> {
  late final PopoverMutex popoverMutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalendarSettingBloc(
        viewId: widget.viewId,
        layoutSettings: widget.calendarSettingController.getLayoutSetting(),
      )..add(const CalendarSettingEvent.init()),
      child: BlocBuilder<CalendarSettingBloc, CalendarSettingState>(
        builder: (context, state) {
          final CalendarLayoutSettingPB? settings = state.layoutSetting
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
                  onUpdated: (showWeekNumbers) => _updateLayoutSettings(
                    context,
                    showWeekNumbers: showWeekNumbers,
                  ),
                );
              case CalendarLayoutSettingAction.showWeekends:
                return ShowWeekends(
                  showWeekends: settings.showWeekends,
                  onUpdated: (showWeekends) => _updateLayoutSettings(
                    context,
                    showWeekends: showWeekends,
                  ),
                );
              case CalendarLayoutSettingAction.firstDayOfWeek:
                return FirstDayOfWeek(
                  firstDayOfWeek: settings.firstDayOfWeek,
                  popoverMutex: popoverMutex,
                  onUpdated: (firstDayOfWeek) => _updateLayoutSettings(
                    context,
                    firstDayOfWeek: firstDayOfWeek,
                  ),
                );
              case CalendarLayoutSettingAction.layoutField:
                return LayoutDateField(
                  fieldController: widget.fieldController,
                  viewId: widget.viewId,
                  fieldId: settings.fieldId,
                  popoverMutex: popoverMutex,
                  onUpdated: (fieldId) => _updateLayoutSettings(
                    context,
                    layoutFieldId: fieldId,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          }).toList();

          return SizedBox(
            width: 200,
            child: ListView.separated(
              shrinkWrap: true,
              controller: ScrollController(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  VSpace(GridSize.typeOptionSeparatorHeight),
              physics: StyledScrollPhysics(),
              itemBuilder: (_, int index) => items[index],
              padding: const EdgeInsets.all(6.0),
            ),
          );
        },
      ),
    );
  }

  List<CalendarLayoutSettingAction> _availableCalendarSettings(
    CalendarLayoutSettingPB layoutSettings,
  ) {
    final List<CalendarLayoutSettingAction> settings = [
      CalendarLayoutSettingAction.layoutField,
    ];

    switch (layoutSettings.layoutTy) {
      case CalendarLayoutPB.DayLayout:
        break;
      case CalendarLayoutPB.MonthLayout:
      case CalendarLayoutPB.WeekLayout:
        settings.add(CalendarLayoutSettingAction.firstDayOfWeek);
        break;
    }

    return settings;
  }

  void _updateLayoutSettings(
    BuildContext context, {
    bool? showWeekends,
    bool? showWeekNumbers,
    int? firstDayOfWeek,
    String? layoutFieldId,
  }) {
    CalendarLayoutSettingPB setting = context
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

      if (layoutFieldId != null) {
        setting.fieldId = layoutFieldId;
      }
    });

    context
        .read<CalendarSettingBloc>()
        .add(CalendarSettingEvent.updateLayoutSetting(setting));

    widget.calendarSettingController.updateLayoutSettings(setting);
  }
}

class LayoutDateField extends StatelessWidget {
  const LayoutDateField({
    super.key,
    required this.fieldId,
    required this.fieldController,
    required this.viewId,
    required this.popoverMutex,
    required this.onUpdated,
  });

  final String fieldId;
  final String viewId;
  final FieldController fieldController;
  final PopoverMutex popoverMutex;
  final Function(String fieldId) onUpdated;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithTopAligned,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      mutex: popoverMutex,
      offset: const Offset(-14, 0),
      popupBuilder: (context) {
        return BlocProvider(
          create: (context) => DatabasePropertyBloc(
            viewId: viewId,
            fieldController: fieldController,
          )..add(const DatabasePropertyEvent.initial()),
          child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
            builder: (context, state) {
              final items = state.fieldContexts
                  .where((field) => field.fieldType == FieldType.DateTime)
                  .map(
                (fieldInfo) {
                  return SizedBox(
                    height: GridSize.popoverItemHeight,
                    child: FlowyButton(
                      text: FlowyText.medium(fieldInfo.name),
                      onTap: () {
                        onUpdated(fieldInfo.id);
                        popoverMutex.close();
                      },
                      leftIcon: const FlowySvg(FlowySvgs.grid_s),
                      rightIcon: fieldInfo.id == fieldId
                          ? const FlowySvg(FlowySvgs.check_s)
                          : null,
                    ),
                  );
                },
              ).toList();

              return SizedBox(
                width: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (_, index) => items[index],
                  separatorBuilder: (_, __) =>
                      VSpace(GridSize.typeOptionSeparatorHeight),
                  itemCount: items.length,
                ),
              );
            },
          ),
        );
      },
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
          text: FlowyText.medium(
            LocaleKeys.calendar_settings_layoutDateField.tr(),
          ),
        ),
      ),
    );
  }
}

class ShowWeekNumber extends StatelessWidget {
  const ShowWeekNumber({
    super.key,
    required this.showWeekNumbers,
    required this.onUpdated,
  });

  final bool showWeekNumbers;
  final Function(bool showWeekNumbers) onUpdated;

  @override
  Widget build(BuildContext context) {
    return _toggleItem(
      onToggle: (showWeekNumbers) => onUpdated(!showWeekNumbers),
      value: showWeekNumbers,
      text: LocaleKeys.calendar_settings_showWeekNumbers.tr(),
    );
  }
}

class ShowWeekends extends StatelessWidget {
  const ShowWeekends({
    super.key,
    required this.showWeekends,
    required this.onUpdated,
  });

  final bool showWeekends;
  final Function(bool showWeekends) onUpdated;

  @override
  Widget build(BuildContext context) {
    return _toggleItem(
      onToggle: (showWeekends) => onUpdated(!showWeekends),
      value: showWeekends,
      text: LocaleKeys.calendar_settings_showWeekends.tr(),
    );
  }
}

class FirstDayOfWeek extends StatelessWidget {
  const FirstDayOfWeek({
    super.key,
    required this.firstDayOfWeek,
    required this.popoverMutex,
    required this.onUpdated,
  });

  final int firstDayOfWeek;
  final PopoverMutex popoverMutex;
  final Function(int firstDayOfWeek) onUpdated;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      mutex: popoverMutex,
      offset: const Offset(-14, 0),
      popupBuilder: (context) {
        final symbols =
            DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
        // starts from sunday
        const len = 2;
        final items = symbols.WEEKDAYS.take(len).indexed.map((entry) {
          return StartFromButton(
            title: entry.$2,
            dayIndex: entry.$1,
            isSelected: firstDayOfWeek == entry.$1,
            onTap: (index) {
              onUpdated(index);
              popoverMutex.close();
            },
          );
        }).toList();

        return SizedBox(
          width: 100,
          child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (_, index) => items[index],
            separatorBuilder: (_, __) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            itemCount: len,
          ),
        );
      },
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
          text: FlowyText.medium(
            LocaleKeys.calendar_settings_firstDayOfWeek.tr(),
          ),
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

class StartFromButton extends StatelessWidget {
  const StartFromButton({
    super.key,
    required this.title,
    required this.dayIndex,
    required this.onTap,
    required this.isSelected,
  });

  final String title;
  final int dayIndex;
  final void Function(int) onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(title),
        onTap: () => onTap(dayIndex),
        rightIcon: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
      ),
    );
  }
}

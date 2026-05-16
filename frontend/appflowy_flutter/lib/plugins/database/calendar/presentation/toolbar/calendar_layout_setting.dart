import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget that displays a list of settings that alters the appearance of the
/// calendar
class CalendarLayoutSetting extends StatefulWidget {
  const CalendarLayoutSetting({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  State<CalendarLayoutSetting> createState() => _CalendarLayoutSettingState();
}

class _CalendarLayoutSettingState extends State<CalendarLayoutSetting> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return CalendarSettingBloc(
          databaseController: widget.databaseController,
        )..add(const CalendarSettingEvent.initial());
      },
      child: BlocBuilder<CalendarSettingBloc, CalendarSettingState>(
        builder: (context, state) {
          final CalendarLayoutSettingPB? settings = state.layoutSetting;

          if (settings == null) {
            return const CircularProgressIndicator();
          }
          final availableSettings = _availableCalendarSettings(settings);
          final bloc = context.read<CalendarSettingBloc>();
          final items = availableSettings.map((setting) {
            switch (setting) {
              case CalendarLayoutSettingAction.showWeekNumber:
                return ShowWeekNumber(
                  showWeekNumbers: settings.showWeekNumbers,
                  onUpdated: (showWeekNumbers) => bloc.add(
                    CalendarSettingEvent.updateLayoutSetting(
                      showWeekNumbers: showWeekNumbers,
                    ),
                  ),
                );
              case CalendarLayoutSettingAction.showWeekends:
                return ShowWeekends(
                  showWeekends: settings.showWeekends,
                  onUpdated: (showWeekends) => bloc.add(
                    CalendarSettingEvent.updateLayoutSetting(
                      showWeekends: showWeekends,
                    ),
                  ),
                );
              case CalendarLayoutSettingAction.firstDayOfWeek:
                return FirstDayOfWeek(
                  firstDayOfWeek: settings.firstDayOfWeek,
                  popoverMutex: popoverMutex,
                  onUpdated: (firstDayOfWeek) => bloc.add(
                    CalendarSettingEvent.updateLayoutSetting(
                      firstDayOfWeek: firstDayOfWeek,
                    ),
                  ),
                );
              case CalendarLayoutSettingAction.layoutField:
                return LayoutDateField(
                  databaseController: widget.databaseController,
                  fieldId: settings.fieldId,
                  popoverMutex: popoverMutex,
                  onUpdated: (fieldId) => bloc.add(
                    CalendarSettingEvent.updateLayoutSetting(
                      layoutFieldId: fieldId,
                    ),
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
}

class LayoutDateField extends StatelessWidget {
  const LayoutDateField({
    super.key,
    required this.databaseController,
    required this.fieldId,
    required this.popoverMutex,
    required this.onUpdated,
  });

  final DatabaseController databaseController;
  final String fieldId;
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
            viewId: databaseController.viewId,
            fieldController: databaseController.fieldController,
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
                      text: FlowyText(
                        fieldInfo.name,
                        lineHeight: 1.0,
                      ),
                      onTap: () {
                        onUpdated(fieldInfo.id);
                        popoverMutex.close();
                      },
                      leftIcon: const FlowySvg(FlowySvgs.date_s),
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
          text: FlowyText(
            lineHeight: 1.0,
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
          text: FlowyText(
            lineHeight: 1.0,
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
          FlowyText(text),
          const Spacer(),
          Toggle(
            value: value,
            onChanged: (value) => onToggle(value),
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
        text: FlowyText(
          title,
          lineHeight: 1.0,
        ),
        onTap: () => onTap(dayIndex),
        rightIcon: isSelected ? const FlowySvg(FlowySvgs.check_s) : null,
      ),
    );
  }
}

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart';

import 'calendar_setting.dart';

/// Widget that displays a list of settings that alters the appearance of the
/// calendar
class CalendarLayoutSetting extends StatefulWidget {
  final CalendarSettingContext settingContext;
  final Function(CalendarLayoutSettingPB? layoutSettings) onUpdated;

  const CalendarLayoutSetting({
    required this.onUpdated,
    required this.settingContext,
    super.key,
  });

  @override
  State<CalendarLayoutSetting> createState() => _CalendarLayoutSettingState();
}

class _CalendarLayoutSettingState extends State<CalendarLayoutSetting> {
  late final PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarSettingBloc, CalendarSettingState>(
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
                onUpdated: (showWeekNumbers) {
                  _updateLayoutSettings(
                    context,
                    showWeekNumbers: showWeekNumbers,
                    onUpdated: widget.onUpdated,
                  );
                },
              );
            case CalendarLayoutSettingAction.showWeekends:
              return ShowWeekends(
                showWeekends: settings.showWeekends,
                onUpdated: (showWeekends) {
                  _updateLayoutSettings(
                    context,
                    showWeekends: showWeekends,
                    onUpdated: widget.onUpdated,
                  );
                },
              );
            case CalendarLayoutSettingAction.firstDayOfWeek:
              return FirstDayOfWeek(
                firstDayOfWeek: settings.firstDayOfWeek,
                popoverMutex: popoverMutex,
                onUpdated: (firstDayOfWeek) {
                  _updateLayoutSettings(
                    context,
                    onUpdated: widget.onUpdated,
                    firstDayOfWeek: firstDayOfWeek,
                  );
                },
              );
            case CalendarLayoutSettingAction.layoutField:
              return LayoutDateField(
                fieldController: widget.settingContext.fieldController,
                viewId: widget.settingContext.viewId,
                fieldId: settings.fieldId,
                popoverMutex: popoverMutex,
                onUpdated: (fieldId) {
                  _updateLayoutSettings(
                    context,
                    onUpdated: widget.onUpdated,
                    layoutFieldId: fieldId,
                  );
                },
              );
            default:
              return const SizedBox();
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
    CalendarLayoutSettingPB layoutSettings,
  ) {
    final List<CalendarLayoutSettingAction> settings = [
      CalendarLayoutSettingAction.layoutField,
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
    required Function(CalendarLayoutSettingPB? layoutSettings) onUpdated,
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
    onUpdated(setting);
  }
}

class LayoutDateField extends StatelessWidget {
  final String fieldId;
  final String viewId;
  final FieldController fieldController;
  final PopoverMutex popoverMutex;
  final Function(String fieldId) onUpdated;

  const LayoutDateField({
    required this.fieldId,
    required this.fieldController,
    required this.viewId,
    required this.popoverMutex,
    required this.onUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      mutex: popoverMutex,
      offset: const Offset(-16, 0),
      popupBuilder: (context) {
        return BlocProvider(
          create: (context) => getIt<DatabasePropertyBloc>(
            param1: viewId,
            param2: fieldController,
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
                      leftIcon: const FlowySvg(name: 'grid/field/date'),
                      rightIcon: fieldInfo.id == fieldId
                          ? const FlowySvg(name: 'grid/checkmark')
                          : null,
                    ),
                  );
                },
              ).toList();

              return SizedBox(
                width: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) => items[index],
                  separatorBuilder: (context, index) =>
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
  final bool showWeekNumbers;
  final Function(bool showWeekNumbers) onUpdated;

  const ShowWeekNumber({
    required this.showWeekNumbers,
    required this.onUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _toggleItem(
      onToggle: (showWeekNumbers) {
        onUpdated(!showWeekNumbers);
      },
      value: showWeekNumbers,
      text: LocaleKeys.calendar_settings_showWeekNumbers.tr(),
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
      text: LocaleKeys.calendar_settings_showWeekends.tr(),
    );
  }
}

class FirstDayOfWeek extends StatelessWidget {
  final int firstDayOfWeek;
  final PopoverMutex popoverMutex;
  final Function(int firstDayOfWeek) onUpdated;
  const FirstDayOfWeek({
    super.key,
    required this.firstDayOfWeek,
    required this.onUpdated,
    required this.popoverMutex,
  });

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.leftWithTopAligned,
      constraints: BoxConstraints.loose(const Size(300, 400)),
      mutex: popoverMutex,
      offset: const Offset(-16, 0),
      popupBuilder: (context) {
        final symbols =
            DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
        // starts from sunday
        final items = symbols.WEEKDAYS.asMap().entries.map((entry) {
          final index = entry.key;
          final string = entry.value;
          return SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyButton(
              text: FlowyText.medium(string),
              onTap: () {
                onUpdated(index);
                popoverMutex.close();
              },
              rightIcon: firstDayOfWeek == index
                  ? const FlowySvg(name: 'grid/checkmark')
                  : null,
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

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_paginated_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/setting/property_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

class MobileCalendarLayoutSetting extends StatefulWidget {
  const MobileCalendarLayoutSetting({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.calendarSettingController,
  });

  final String viewId;
  final FieldController fieldController;
  final ICalendarSetting calendarSettingController;

  @override
  State<MobileCalendarLayoutSetting> createState() =>
      _MobileCalendarLayoutSettingState();
}

class _MobileCalendarLayoutSettingState
    extends State<MobileCalendarLayoutSetting> {
  late final PopoverMutex popoverMutex = PopoverMutex();
  late final CalendarSettingBloc calendarSettingBloc;

  @override
  void initState() {
    super.initState();
    calendarSettingBloc = CalendarSettingBloc(
      viewId: widget.viewId,
      layoutSettings: widget.calendarSettingController.getLayoutSetting(),
    )..add(const CalendarSettingEvent.init());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarSettingBloc>.value(
      value: calendarSettingBloc,
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
              case CalendarLayoutSettingAction.firstDayOfWeek:
                return MobileFirstDayOfWeekSetting(
                  selectedDay: settings.firstDayOfWeek,
                  onUpdated: (firstDayOfWeek) => _updateLayoutSettings(
                    context,
                    firstDayOfWeek: firstDayOfWeek,
                  ),
                );
              case CalendarLayoutSettingAction.layoutField:
                return MobileLayoutDateField(
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

          return ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            physics: StyledScrollPhysics(),
            itemBuilder: (_, int index) => items[index],
            padding: const EdgeInsets.all(6.0),
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
    CalendarLayoutSettingPB setting = calendarSettingBloc.state.layoutSetting
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

    calendarSettingBloc.add(CalendarSettingEvent.updateLayoutSetting(setting));
    widget.calendarSettingController.updateLayoutSettings(setting);
  }
}

class MobileLayoutDateField extends StatelessWidget {
  const MobileLayoutDateField({
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
    return BlocProvider(
      create: (context) => DatabasePropertyBloc(
        viewId: viewId,
        fieldController: fieldController,
      )..add(const DatabasePropertyEvent.initial()),
      child: BlocBuilder<DatabasePropertyBloc, DatabasePropertyState>(
        builder: (context, state) {
          final items = state.fieldContexts
              .where((field) => field.fieldType == FieldType.DateTime)
              .toList();
          final selected = items.firstWhere((field) => field.id == fieldId);

          return MobileSettingItem(
            padding: EdgeInsets.zero,
            name: LocaleKeys.calendar_settings_layoutDateField.tr(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FlowyText(
                    selected.name,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showSelector(context, items),
          );
        },
      ),
    );
  }

  void _showSelector(BuildContext context, List<FieldInfo> items) =>
      FlowyBottomSheetController.of(context)!.push(
        SheetPage(
          title: LocaleKeys.settings_mobile_selectStartingDay.tr(),
          body: MobileCalendarLayoutSelector(
            fieldId: fieldId,
            items: items,
            onUpdated: onUpdated,
          ),
        ),
      );
}

class MobileCalendarLayoutSelector extends StatefulWidget {
  const MobileCalendarLayoutSelector({
    super.key,
    required this.fieldId,
    required this.items,
    required this.onUpdated,
  });

  final String fieldId;
  final List<FieldInfo> items;
  final Function(String fieldId) onUpdated;

  @override
  State<MobileCalendarLayoutSelector> createState() =>
      _MobileCalendarLayoutSelectorState();
}

class _MobileCalendarLayoutSelectorState
    extends State<MobileCalendarLayoutSelector> {
  late String _selectedField = widget.fieldId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const VSpace(4),
      itemBuilder: (_, index) => MobileSettingItem(
        name: widget.items[index].name,
        trailing: _selectedField == widget.items[index].id
            ? const FlowySvg(FlowySvgs.check_s)
            : null,
        onTap: () {
          final selected = widget.items[index].id;
          widget.onUpdated(selected);
          setState(() => _selectedField = selected);
        },
      ),
    );
  }
}

const weekdayOptions = 2;

class MobileFirstDayOfWeekSetting extends StatelessWidget {
  const MobileFirstDayOfWeekSetting({
    super.key,
    required this.selectedDay,
    required this.onUpdated,
  });

  final int selectedDay;
  final Function(int firstDayOfWeek) onUpdated;

  @override
  Widget build(BuildContext context) {
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    final weekdays = symbols.WEEKDAYS.take(weekdayOptions).toList();

    return MobileSettingItem(
      padding: EdgeInsets.zero,
      name: LocaleKeys.calendar_settings_firstDayOfWeek.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FlowyText(
              weekdays[selectedDay],
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _showSelector(context),
    );
  }

  void _showSelector(BuildContext context) =>
      FlowyBottomSheetController.of(context)!.push(
        SheetPage(
          title: LocaleKeys.calendar_settings_layoutDateField.tr(),
          body: MobileFirstDayOfWeekSelector(
            selectedDay: selectedDay,
            onUpdated: onUpdated,
          ),
        ),
      );
}

class MobileFirstDayOfWeekSelector extends StatefulWidget {
  const MobileFirstDayOfWeekSelector({
    super.key,
    required this.selectedDay,
    required this.onUpdated,
  });

  final int selectedDay;
  final Function(int firstDayOfWeek) onUpdated;

  @override
  State<MobileFirstDayOfWeekSelector> createState() =>
      _MobileFirstDayOfWeekSelectorState();
}

class _MobileFirstDayOfWeekSelectorState
    extends State<MobileFirstDayOfWeekSelector> {
  late int _selectedDay = widget.selectedDay;

  @override
  Widget build(BuildContext context) {
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    final weekdays = symbols.WEEKDAYS.take(weekdayOptions).toList();

    return ListView.separated(
      shrinkWrap: true,
      itemCount: weekdayOptions,
      separatorBuilder: (_, __) => const VSpace(4),
      itemBuilder: (_, index) => MobileSettingItem(
        name: weekdays[index],
        trailing:
            _selectedDay == index ? const FlowySvg(FlowySvgs.check_s) : null,
        onTap: () {
          widget.onUpdated(index);
          setState(() => _selectedDay = index);
        },
      ),
    );
  }
}

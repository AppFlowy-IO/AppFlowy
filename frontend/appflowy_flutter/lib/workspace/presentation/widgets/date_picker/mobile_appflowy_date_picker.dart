import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_option_decorate_box.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_editor.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileAppFlowyDatePicker extends StatefulWidget {
  const MobileAppFlowyDatePicker({
    super.key,
    this.dateTime,
    this.endDateTime,
    required this.dateFormat,
    required this.timeFormat,
    this.reminderOption = ReminderOption.none,
    required this.includeTime,
    required this.onIncludeTimeChanged,
    this.isRange = false,
    this.onIsRangeChanged,
    this.onDaySelected,
    this.onRangeSelected,
    this.onClearDate,
    this.onReminderSelected,
  });

  final DateTime? dateTime;
  final DateTime? endDateTime;

  final bool isRange;
  final bool includeTime;

  final TimeFormatPB timeFormat;
  final DateFormatPB dateFormat;

  final ReminderOption reminderOption;

  final Function(bool)? onIncludeTimeChanged;
  final Function(bool)? onIsRangeChanged;

  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;
  final VoidCallback? onClearDate;
  final OnReminderSelected? onReminderSelected;

  @override
  State<MobileAppFlowyDatePicker> createState() =>
      _MobileAppFlowyDatePickerState();
}

class _MobileAppFlowyDatePickerState extends State<MobileAppFlowyDatePicker> {
  // store date values in the state and refresh the ui upon any changes made, instead of only updating them after receiving update from backend.
  late DateTime? dateTime;
  late DateTime? startDateTime;
  late DateTime? endDateTime;
  late bool includeTime;
  late bool isRange;
  late ReminderOption reminderOption;

  late DateTime focusedDateTime;
  PageController? pageController;

  bool justChangedIsRange = false;

  @override
  void initState() {
    super.initState();

    dateTime = widget.dateTime;
    startDateTime = widget.isRange ? widget.dateTime : null;
    endDateTime = widget.isRange ? widget.endDateTime : null;
    includeTime = widget.includeTime;
    isRange = widget.isRange;
    reminderOption = widget.reminderOption;

    focusedDateTime = widget.dateTime ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    setState(() {
      dateTime = widget.dateTime;
      if (widget.isRange) {
        startDateTime = widget.dateTime;
        endDateTime = widget.endDateTime;
      } else {
        startDateTime = endDateTime = null;
      }
      includeTime = widget.includeTime;
      isRange = widget.isRange;
      if (oldWidget.reminderOption != widget.reminderOption) {
        reminderOption = widget.reminderOption;
      }
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyOptionDecorateBox(
          showTopBorder: false,
          child: _TimePicker(
            dateTime: isRange ? startDateTime : dateTime,
            endDateTime: endDateTime,
            includeTime: includeTime,
            isRange: isRange,
            dateFormat: widget.dateFormat,
            timeFormat: widget.timeFormat,
            onStartTimeChanged: onStartTimeChanged,
            onEndTimeChanged: onEndTimeChanged,
          ),
        ),
        const _Divider(),
        FlowyOptionDecorateBox(
          child: MobileDatePicker(
            isRange: isRange,
            selectedDay: dateTime,
            startDay: isRange ? startDateTime : null,
            endDay: isRange ? endDateTime : null,
            focusedDay: focusedDateTime,
            onDaySelected: (selectedDay) {
              onDateSelectedFromDatePicker(selectedDay, null);
            },
            onRangeSelected: (start, end) {
              onDateSelectedFromDatePicker(start, end);
            },
            onPageChanged: (focusedDay) {
              setState(() => focusedDateTime = focusedDay);
            },
          ),
        ),
        const _Divider(),
        if (widget.onIsRangeChanged != null)
          _IsRangeSwitch(
            isRange: widget.isRange,
            onRangeChanged: (value) {
              if (!isRange) {
                justChangedIsRange = true;
              }
              widget.onIsRangeChanged!.call(value);
              setState(() => isRange = value);
            },
          ),
        if (widget.onIncludeTimeChanged != null)
          _IncludeTimeSwitch(
            showTopBorder: widget.onIsRangeChanged == null,
            includeTime: includeTime,
            onIncludeTimeChanged: (includeTime) {
              widget.onIncludeTimeChanged?.call(includeTime);
              setState(() => this.includeTime = includeTime);
            },
          ),
        if (widget.onReminderSelected != null) ...[
          const _Divider(),
          _ReminderSelector(
            selectedReminderOption: reminderOption,
            onReminderSelected: (option) {
              widget.onReminderSelected!.call(option);
              setState(() => reminderOption = option);
            },
            timeFormat: widget.timeFormat,
            hasTime: widget.includeTime,
          ),
        ],
        if (widget.onClearDate != null) ...[
          const _Divider(),
          _ClearDateButton(
            onClearDate: () {
              widget.onClearDate!.call();
              Navigator.of(context).pop();
            },
          ),
        ],
        const _Divider(),
      ],
    );
  }

  void onDateSelectedFromDatePicker(
    DateTime? newStartDateTime,
    DateTime? newEndDateTime,
  ) {
    if (newStartDateTime == null) {
      return;
    }
    if (isRange) {
      if (newEndDateTime == null) {
        if (justChangedIsRange && dateTime != null) {
          justChangedIsRange = false;
          DateTime start = dateTime!;
          DateTime end = DateTime(
            newStartDateTime.year,
            newStartDateTime.month,
            newStartDateTime.day,
          );
          if (end.isBefore(start)) {
            (start, end) = (end, start);
          }
          widget.onRangeSelected?.call(start, end);
          setState(() {
            // hAcK: Resetting these state variables to null to reset the click counter of the table calendar widget, which doesn't expose a controller for us to do so otherwise. The parent widget needs to provide the data again so that it can be shown.
            dateTime = startDateTime = endDateTime = null;
            focusedDateTime = getNewFocusedDay(newStartDateTime);
          });
        } else {
          final combined = combineDateTimes(newStartDateTime, dateTime);
          setState(() {
            dateTime = combined;
            startDateTime = combined;
            endDateTime = null;
            focusedDateTime = getNewFocusedDay(combined);
          });
        }
      } else {
        bool switched = false;
        DateTime combinedDateTime =
            combineDateTimes(newStartDateTime, dateTime);
        DateTime combinedEndDateTime =
            combineDateTimes(newEndDateTime, widget.endDateTime);

        if (combinedEndDateTime.isBefore(combinedDateTime)) {
          (combinedDateTime, combinedEndDateTime) =
              (combinedEndDateTime, combinedDateTime);
          switched = true;
        }

        widget.onRangeSelected?.call(combinedDateTime, combinedEndDateTime);

        setState(() {
          dateTime = switched ? combinedDateTime : combinedEndDateTime;
          startDateTime = combinedDateTime;
          endDateTime = combinedEndDateTime;
          focusedDateTime = getNewFocusedDay(newEndDateTime);
        });
      }
    } else {
      final combinedDateTime = combineDateTimes(newStartDateTime, dateTime);
      widget.onDaySelected?.call(combinedDateTime);

      setState(() {
        dateTime = combinedDateTime;
        focusedDateTime = getNewFocusedDay(combinedDateTime);
      });
    }
  }

  DateTime combineDateTimes(DateTime date, DateTime? time) {
    final timeComponent = time == null
        ? Duration.zero
        : Duration(hours: time.hour, minutes: time.minute);

    return DateTime(date.year, date.month, date.day).add(timeComponent);
  }

  void onStartTimeChanged(DateTime value) {
    if (isRange) {
      DateTime end = endDateTime ?? value;
      if (end.isBefore(value)) {
        (value, end) = (end, value);
      }

      widget.onRangeSelected?.call(value, end);

      setState(() {
        dateTime = value;
        startDateTime = value;
        endDateTime = end;
        focusedDateTime = getNewFocusedDay(value);
      });
    } else {
      widget.onDaySelected?.call(value);

      setState(() {
        dateTime = value;
        focusedDateTime = getNewFocusedDay(value);
      });
    }
  }

  void onEndTimeChanged(DateTime value) {
    if (isRange) {
      DateTime start = startDateTime ?? value;
      if (value.isBefore(start)) {
        (start, value) = (value, start);
      }

      widget.onRangeSelected?.call(start, value);

      if (endDateTime == null) {
        // hAcK: Resetting these state variables to null to reset the click counter of the table calendar widget, which doesn't expose a controller for us to do so otherwise. The parent widget needs to provide the data again so that it can be shown.
        setState(() {
          dateTime = startDateTime = endDateTime = null;
          focusedDateTime = getNewFocusedDay(value);
        });
      } else {
        setState(() {
          dateTime = start;
          startDateTime = start;
          endDateTime = value;
          focusedDateTime = getNewFocusedDay(value);
        });
      }
    } else {
      widget.onDaySelected?.call(value);

      setState(() {
        dateTime = value;
        focusedDateTime = getNewFocusedDay(value);
      });
    }
  }

  DateTime getNewFocusedDay(DateTime dateTime) {
    if (focusedDateTime.year != dateTime.year ||
        focusedDateTime.month != dateTime.month) {
      return DateTime(dateTime.year, dateTime.month);
    } else {
      return focusedDateTime;
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const VSpace(20.0);
}

class _ReminderSelector extends StatelessWidget {
  const _ReminderSelector({
    this.selectedReminderOption,
    required this.onReminderSelected,
    required this.timeFormat,
    this.hasTime = false,
  });

  final ReminderOption? selectedReminderOption;
  final OnReminderSelected onReminderSelected;
  final TimeFormatPB timeFormat;
  final bool hasTime;

  @override
  Widget build(BuildContext context) {
    final option = selectedReminderOption ?? ReminderOption.none;

    final availableOptions = [...ReminderOption.values];
    if (option != ReminderOption.custom) {
      availableOptions.remove(ReminderOption.custom);
    }

    availableOptions.removeWhere(
      (o) => !o.timeExempt && (!hasTime ? !o.withoutTime : o.requiresNoTime),
    );

    return FlowyOptionTile.text(
      text: LocaleKeys.datePicker_reminderLabel.tr(),
      trailing: Row(
        children: [
          const HSpace(6.0),
          FlowyText(
            option.label,
            color: Theme.of(context).hintColor,
          ),
          const HSpace(4.0),
          FlowySvg(
            FlowySvgs.arrow_right_s,
            color: Theme.of(context).hintColor,
            size: const Size.square(18.0),
          ),
        ],
      ),
      onTap: () => showMobileBottomSheet(
        context,
        builder: (_) => DraggableScrollableSheet(
          expand: false,
          snap: true,
          initialChildSize: 0.7,
          minChildSize: 0.7,
          builder: (context, controller) => Column(
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: const Center(child: DragHandle()),
              ),
              const _ReminderSelectHeader(),
              Flexible(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: availableOptions.map<Widget>(
                      (o) {
                        String label = o.label;
                        if (o.withoutTime && !o.timeExempt) {
                          const time = "09:00";
                          final t = timeFormat == TimeFormatPB.TwelveHour
                              ? "$time AM"
                              : time;

                          label = "$label ($t)";
                        }

                        return FlowyOptionTile.text(
                          text: label,
                          showTopBorder: o == ReminderOption.none,
                          onTap: () {
                            onReminderSelected(o);
                            context.pop();
                          },
                        );
                      },
                    ).toList()
                      ..insert(0, const _Divider()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderSelectHeader extends StatelessWidget {
  const _ReminderSelectHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: AppBarCancelButton(onTap: context.pop),
          ),
          FlowyText.medium(
            LocaleKeys.datePicker_selectReminder.tr(),
            fontSize: 17.0,
          ),
          const HSpace(120),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  const _TimePicker({
    required this.dateTime,
    required this.endDateTime,
    required this.dateFormat,
    required this.timeFormat,
    required this.includeTime,
    required this.isRange,
    required this.onStartTimeChanged,
    this.onEndTimeChanged,
  });

  final DateTime? dateTime;
  final DateTime? endDateTime;

  final bool includeTime;
  final bool isRange;

  final DateFormatPB dateFormat;
  final TimeFormatPB timeFormat;

  final void Function(DateTime time) onStartTimeChanged;
  final void Function(DateTime time)? onEndTimeChanged;

  @override
  Widget build(BuildContext context) {
    final dateStr = getDateStr(dateTime);
    final timeStr = getTimeStr(dateTime);
    final endDateStr = getDateStr(endDateTime);
    final endTimeStr = getTimeStr(endDateTime);

    if (dateStr.isEmpty) {
      return const Divider(height: 1);
    }

    if (endDateStr.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: _buildTime(
          context,
          dateStr,
          timeStr,
          includeTime,
          false,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTime(
            context,
            dateStr,
            timeStr,
            includeTime,
            true,
          ),
          VSpace(8.0, color: Theme.of(context).colorScheme.surface),
          _buildTime(
            context,
            endDateStr,
            endTimeStr,
            includeTime,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildTime(
    BuildContext context,
    String? dateStr,
    String? timeStr,
    bool includeTime,
    bool isStartDay,
  ) {
    if (dateStr == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = [];

    if (!includeTime) {
      children.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GestureDetector(
              onTap: () async {
                final result = await _showDateTimePicker(
                  context,
                  isStartDay ? dateTime : endDateTime,
                  use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                  mode: CupertinoDatePickerMode.date,
                );
                handleDateTimePickerResult(result, isStartDay);
              },
              child: FlowyText(dateStr),
            ),
          ),
        ),
      );
    } else {
      children.addAll([
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final result = await _showDateTimePicker(
                context,
                isStartDay ? dateTime : endDateTime,
                use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                mode: CupertinoDatePickerMode.date,
              );
              handleDateTimePickerResult(result, isStartDay);
            },
            child: FlowyText(
              dateStr,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Container(
          width: 1,
          height: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final result = await _showDateTimePicker(
                context,
                isStartDay ? dateTime : endDateTime,
                use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                mode: CupertinoDatePickerMode.time,
              );
              handleDateTimePickerResult(result, isStartDay);
            },
            child: FlowyText(
              timeStr!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ]);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(children: children),
    );
  }

  Future<DateTime?> _showDateTimePicker(
    BuildContext context,
    DateTime? dateTime, {
    required CupertinoDatePickerMode mode,
    required bool use24hFormat,
  }) async {
    DateTime? result;

    return showMobileBottomSheet(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: CupertinoDatePicker(
              mode: mode,
              initialDateTime: dateTime,
              use24hFormat: use24hFormat,
              onDateTimeChanged: (dateTime) {
                result = dateTime;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: FlowyTextButton(
              LocaleKeys.button_confirm.tr(),
              constraints: const BoxConstraints.tightFor(height: 42),
              mainAxisAlignment: MainAxisAlignment.center,
              fontColor: Theme.of(context).colorScheme.onPrimary,
              fillColor: Theme.of(context).primaryColor,
              onPressed: () {
                Navigator.of(context).pop(result);
              },
            ),
          ),
          const VSpace(18.0),
        ],
      ),
    );
  }

  void handleDateTimePickerResult(DateTime? result, bool isStartDay) {
    if (result == null) {
      return;
    } else if (isStartDay) {
      onStartTimeChanged(result);
    } else {
      onEndTimeChanged?.call(result);
    }
  }

  String getDateStr(DateTime? dateTime) {
    if (dateTime == null) {
      return "";
    }
    final format = DateFormat(
      switch (dateFormat) {
        DateFormatPB.Local => 'MM/dd/y',
        DateFormatPB.US => 'y/MM/dd',
        DateFormatPB.ISO => 'y-MM-dd',
        DateFormatPB.Friendly => 'MMM dd, y',
        DateFormatPB.DayMonthYear => 'dd/MM/y',
        _ => 'MMM dd, y',
      },
    );

    return format.format(dateTime);
  }

  String getTimeStr(DateTime? dateTime) {
    if (dateTime == null || !includeTime) {
      return "";
    }
    final format = timeFormat == TimeFormatPB.TwelveHour
        ? DateFormat.jm()
        : DateFormat.Hm();

    return format.format(dateTime);
  }
}

class _IsRangeSwitch extends StatelessWidget {
  const _IsRangeSwitch({
    required this.isRange,
    required this.onRangeChanged,
  });

  final bool isRange;
  final Function(bool) onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.toggle(
      text: LocaleKeys.grid_field_isRange.tr(),
      isSelected: isRange,
      onValueChanged: onRangeChanged,
    );
  }
}

class _IncludeTimeSwitch extends StatelessWidget {
  const _IncludeTimeSwitch({
    this.showTopBorder = true,
    required this.includeTime,
    required this.onIncludeTimeChanged,
  });

  final bool showTopBorder;
  final bool includeTime;
  final Function(bool) onIncludeTimeChanged;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.toggle(
      showTopBorder: showTopBorder,
      text: LocaleKeys.grid_field_includeTime.tr(),
      isSelected: includeTime,
      onValueChanged: onIncludeTimeChanged,
    );
  }
}

class _ClearDateButton extends StatelessWidget {
  const _ClearDateButton({required this.onClearDate});

  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_field_clearDate.tr(),
      onTap: onClearDate,
    );
  }
}

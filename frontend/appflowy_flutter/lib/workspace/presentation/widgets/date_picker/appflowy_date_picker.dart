import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widgets/date_picker.dart';
import 'widgets/date_time_text_field.dart';
import 'widgets/end_time_button.dart';
import 'widgets/reminder_selector.dart';

class OptionGroup {
  OptionGroup({required this.options});

  final List<Widget> options;
}

typedef DaySelectedCallback = void Function(DateTime);
typedef RangeSelectedCallback = void Function(DateTime, DateTime);
typedef IncludeTimeChangedCallback = void Function(bool);

class AppFlowyDatePicker extends StatefulWidget {
  const AppFlowyDatePicker({
    super.key,
    required this.dateTime,
    this.endDateTime,
    required this.includeTime,
    required this.isRange,
    this.reminderOption = ReminderOption.none,
    required this.dateFormat,
    required this.timeFormat,
    this.popoverMutex,
    this.options = const [],
    this.onDaySelected,
    this.onRangeSelected,
    this.onIncludeTimeChanged,
    this.onIsRangeChanged,
    this.onReminderSelected,
  });

  final DateTime? dateTime;
  final DateTime? endDateTime;

  final DateFormatPB dateFormat;
  final TimeFormatPB timeFormat;

  final PopoverMutex? popoverMutex;

  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;

  final bool includeTime;
  final Function(bool)? onIncludeTimeChanged;

  final bool isRange;
  final Function(bool)? onIsRangeChanged;

  final ReminderOption reminderOption;
  final OnReminderSelected? onReminderSelected;

  /// A list of [OptionGroup] that will be rendered with proper
  /// separators, each group can contain multiple options.
  ///
  /// __Supported on Desktop & Web__
  ///
  final List<OptionGroup> options;

  @override
  State<AppFlowyDatePicker> createState() => AppFlowyDatePickerState();
}

@visibleForTesting
class AppFlowyDatePickerState extends State<AppFlowyDatePicker> {
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

  final isTabPressedNotifier = ValueNotifier<bool>(false);
  final refreshStartTextFieldNotifier = RefreshDateTimeTextFieldController();
  final refreshEndTextFieldNotifier = RefreshDateTimeTextFieldController();

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
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    isTabPressedNotifier.dispose();
    refreshStartTextFieldNotifier.dispose();
    refreshEndTextFieldNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector is a workaround to stop popover from closing
    // when clicking on the date picker.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTimeTextField(
              key: const ValueKey('date_time_text_field'),
              includeTime: includeTime,
              dateTime: isRange ? startDateTime : dateTime,
              dateFormat: widget.dateFormat,
              timeFormat: widget.timeFormat,
              popoverMutex: widget.popoverMutex,
              isTabPressed: isTabPressedNotifier,
              refreshTextController: refreshStartTextFieldNotifier,
              onSubmitted: onDateTimeInputSubmitted,
            ),
            if (isRange) ...[
              const VSpace(8),
              DateTimeTextField(
                key: const ValueKey('end_date_time_text_field'),
                includeTime: includeTime,
                dateTime: endDateTime,
                dateFormat: widget.dateFormat,
                timeFormat: widget.timeFormat,
                popoverMutex: widget.popoverMutex,
                isTabPressed: isTabPressedNotifier,
                refreshTextController: refreshEndTextFieldNotifier,
                onSubmitted: onEndDateTimeInputSubmitted,
              ),
            ],
            const VSpace(14),
            Focus(
              descendantsAreTraversable: false,
              child: _buildDatePickerHeader(),
            ),
            const VSpace(14),
            DatePicker(
              isRange: isRange,
              onDaySelected: (selectedDay, focusedDay) {
                onDateSelectedFromDatePicker(selectedDay, null);
              },
              onRangeSelected: (start, end, focusedDay) {
                onDateSelectedFromDatePicker(start, end);
              },
              selectedDay: dateTime,
              startDay: isRange ? startDateTime : null,
              endDay: isRange ? endDateTime : null,
              focusedDay: focusedDateTime,
              onCalendarCreated: (controller) {
                pageController = controller;
              },
              onPageChanged: (focusedDay) {
                setState(
                  () => focusedDateTime = DateTime(
                    focusedDay.year,
                    focusedDay.month,
                    focusedDay.day,
                  ),
                );
              },
            ),
            if (widget.onIsRangeChanged != null ||
                widget.onIncludeTimeChanged != null)
              const TypeOptionSeparator(spacing: 12.0),
            if (widget.onIsRangeChanged != null) ...[
              EndTimeButton(
                isRange: isRange,
                onChanged: (value) {
                  if (value) {
                    justChangedIsRange = true;
                  }
                  widget.onIsRangeChanged!.call(value);
                  if (dateTime != null && value) {
                    widget.onRangeSelected?.call(dateTime!, dateTime!);
                  }
                  setState(() => isRange = value);
                },
              ),
              const VSpace(4.0),
            ],
            if (widget.onIncludeTimeChanged != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IncludeTimeButton(
                  includeTime: includeTime,
                  onChanged: (value) {
                    widget.onIncludeTimeChanged?.call(value);
                    setState(() => includeTime = value);
                  },
                ),
              ),
            if (widget.onReminderSelected != null) ...[
              const _GroupSeparator(),
              ReminderSelector(
                mutex: widget.popoverMutex,
                hasTime: widget.includeTime,
                timeFormat: widget.timeFormat,
                selectedOption: reminderOption,
                onOptionSelected: (option) {
                  widget.onReminderSelected?.call(option);
                  setState(() => reminderOption = option);
                },
              ),
            ],
            if (widget.options.isNotEmpty) ...[
              const _GroupSeparator(),
              ListView.separated(
                shrinkWrap: true,
                itemCount: widget.options.length,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const _GroupSeparator(),
                itemBuilder: (_, index) =>
                    _renderGroupOptions(widget.options[index].options),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerHeader() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 22.0, end: 18.0),
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              DateFormat.yMMMM().format(focusedDateTime),
            ),
          ),
          FlowyIconButton(
            width: 20,
            icon: FlowySvg(
              FlowySvgs.arrow_left_s,
              color: Theme.of(context).iconTheme.color,
              size: const Size.square(20.0),
            ),
            onPressed: () => pageController?.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
          const HSpace(4.0),
          FlowyIconButton(
            width: 20,
            icon: FlowySvg(
              FlowySvgs.arrow_right_s,
              color: Theme.of(context).iconTheme.color,
              size: const Size.square(20.0),
            ),
            onPressed: () {
              pageController?.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _renderGroupOptions(List<Widget> options) => ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (_, __) => const VSpace(4),
        itemBuilder: (_, index) => options[index],
      );

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

  void onDateTimeInputSubmitted(DateTime value) {
    if (isRange) {
      DateTime end = endDateTime ?? value;
      if (end.isBefore(value)) {
        (value, end) = (end, value);
        refreshStartTextFieldNotifier.refresh();
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

  void onEndDateTimeInputSubmitted(DateTime value) {
    if (isRange) {
      DateTime start = startDateTime ?? value;
      if (value.isBefore(start)) {
        (start, value) = (value, start);
        refreshEndTextFieldNotifier.refresh();
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

class _GroupSeparator extends StatelessWidget {
  const _GroupSeparator();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(color: Theme.of(context).dividerColor, height: 1.0),
      );
}

class RefreshDateTimeTextFieldController extends ChangeNotifier {
  void refresh() => notifyListeners();
}

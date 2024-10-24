import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/widgets.dart';

import 'widgets/reminder_selector.dart';

typedef DaySelectedCallback = void Function(DateTime);
typedef RangeSelectedCallback = void Function(DateTime, DateTime);
typedef IncludeTimeChangedCallback = void Function(bool);

abstract class AppFlowyDatePicker extends StatefulWidget {
  const AppFlowyDatePicker({
    super.key,
    required this.dateTime,
    this.endDateTime,
    required this.includeTime,
    required this.isRange,
    this.reminderOption = ReminderOption.none,
    required this.dateFormat,
    required this.timeFormat,
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

  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;

  final bool includeTime;
  final Function(bool)? onIncludeTimeChanged;

  final bool isRange;
  final Function(bool)? onIsRangeChanged;

  final ReminderOption reminderOption;
  final OnReminderSelected? onReminderSelected;
}

abstract class AppFlowyDatePickerState<T extends AppFlowyDatePicker>
    extends State<T> {
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

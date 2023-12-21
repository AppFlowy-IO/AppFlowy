import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date/date_time_format.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/clear_date_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_type_option_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_text_field.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_time_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/start_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

typedef DaySelectedCallback = Function(DateTime, DateTime);
typedef RangeSelectedCallback = Function(DateTime?, DateTime?, DateTime);
typedef IncludeTimeChangedCallback = Function(bool);
typedef TimeChangedCallback = Function(String);

class AppFlowyDatePicker extends StatefulWidget {
  const AppFlowyDatePicker({
    super.key,
    required this.includeTime,
    required this.onIncludeTimeChanged,
    this.rebuildOnDaySelected = true,
    this.enableRanges = true,
    this.isRange = false,
    this.onIsRangeChanged,
    required this.dateFormat,
    required this.timeFormat,
    this.selectedDay,
    this.focusedDay,
    this.firstDay,
    this.lastDay,
    this.timeStr,
    this.endTimeStr,
    this.timeHintText,
    this.parseEndTimeError,
    this.parseTimeError,
    this.popoverMutex,
    this.onStartTimeSubmitted,
    this.onEndTimeSubmitted,
    this.onDaySelected,
    this.onRangeSelected,
    this.allowFormatChanges = false,
    this.onDateFormatChanged,
    this.onTimeFormatChanged,
    this.onClearDate,
  });

  final bool includeTime;
  final Function(bool) onIncludeTimeChanged;

  final bool enableRanges;
  final bool isRange;
  final Function(bool)? onIsRangeChanged;

  final bool rebuildOnDaySelected;

  final DateFormatPB dateFormat;
  final TimeFormatPB timeFormat;

  final DateTime? selectedDay;
  final DateTime? focusedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final String? timeStr;
  final String? endTimeStr;
  final String? timeHintText;
  final String? parseEndTimeError;
  final String? parseTimeError;
  final PopoverMutex? popoverMutex;

  final TimeChangedCallback? onStartTimeSubmitted;
  final TimeChangedCallback? onEndTimeSubmitted;
  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;

  /// If this value is true, then [onTimeFormatChanged] and [onDateFormatChanged]
  /// cannot be null
  ///
  final bool allowFormatChanges;

  /// If [allowFormatChanges] is true, this must be provided
  ///
  final Function(DateFormatPB)? onDateFormatChanged;

  /// If [allowFormatChanges] is true, this must be provided
  ///
  final Function(TimeFormatPB)? onTimeFormatChanged;

  /// If provided, the ClearDate button will be shown
  /// Otherwise it will be hidden
  ///
  final VoidCallback? onClearDate;

  @override
  State<AppFlowyDatePicker> createState() => _AppFlowyDatePickerState();
}

class _AppFlowyDatePickerState extends State<AppFlowyDatePicker> {
  late DateTime? _selectedDay = widget.selectedDay;

  @override
  void didChangeDependencies() {
    _selectedDay = widget.selectedDay;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StartTextField(
            includeTime: widget.includeTime,
            timeFormat: widget.timeFormat,
            timeHintText: widget.timeHintText,
            parseEndTimeError: widget.parseEndTimeError,
            parseTimeError: widget.parseTimeError,
            timeStr: widget.timeStr,
            popoverMutex: widget.popoverMutex,
            onSubmitted: widget.onStartTimeSubmitted,
          ),
          EndTextField(
            includeTime: widget.includeTime,
            timeFormat: widget.timeFormat,
            isRange: widget.isRange,
            endTimeStr: widget.endTimeStr,
            popoverMutex: widget.popoverMutex,
            onSubmitted: widget.onEndTimeSubmitted,
          ),
          DatePicker(
            isRange: widget.isRange,
            onDaySelected: (selectedDay, focusedDay) {
              widget.onDaySelected?.call(selectedDay, focusedDay);

              if (widget.rebuildOnDaySelected) {
                setState(() => _selectedDay = selectedDay);
              }
            },
            onRangeSelected: widget.onRangeSelected,
            selectedDay: _selectedDay,
            firstDay: widget.firstDay,
            lastDay: widget.lastDay,
          ),
          const TypeOptionSeparator(spacing: 12.0),
          if (widget.enableRanges && widget.onIsRangeChanged != null) ...[
            EndTimeButton(
              isRange: widget.isRange,
              onChanged: widget.onIsRangeChanged!,
            ),
            const VSpace(4.0),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: IncludeTimeButton(
              value: widget.includeTime,
              onChanged: widget.onIncludeTimeChanged,
            ),
          ),
          if (widget.onClearDate != null ||
              (widget.allowFormatChanges &&
                  widget.onDateFormatChanged != null &&
                  widget.onTimeFormatChanged != null))
            // Only show if either of the options are below it
            const TypeOptionSeparator(spacing: 8.0),
          if (widget.allowFormatChanges &&
              widget.onDateFormatChanged != null &&
              widget.onTimeFormatChanged != null)
            DateTypeOptionButton(
              popoverMutex: widget.popoverMutex,
              dateFormat: widget.dateFormat,
              timeFormat: widget.timeFormat,
              onDateFormatChanged: widget.onDateFormatChanged!,
              onTimeFormatChanged: widget.onTimeFormatChanged!,
            ),
          if (widget.onClearDate != null) ...[
            const VSpace(4.0),
            ClearDateButton(onClearDate: widget.onClearDate!),
          ],
        ],
      ),
    );
  }
}

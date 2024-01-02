import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date/date_time_format.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_text_field.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_time_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/start_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class OptionGroup {
  OptionGroup({required this.options});

  final List<Widget> options;
}

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
    this.selectedReminderOption = ReminderOption.none,
    this.onStartTimeSubmitted,
    this.onEndTimeSubmitted,
    this.onDaySelected,
    this.onRangeSelected,
    this.onReminderSelected,
    this.options,
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
  final ReminderOption selectedReminderOption;

  final TimeChangedCallback? onStartTimeSubmitted;
  final TimeChangedCallback? onEndTimeSubmitted;
  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;

  final OnReminderSelected? onReminderSelected;

  /// A list of [OptionGroup] that will be rendered with proper
  /// separators, each group can contain multiple options.
  ///
  final List<OptionGroup>? options;

  @override
  State<AppFlowyDatePicker> createState() => _AppFlowyDatePickerState();
}

class _AppFlowyDatePickerState extends State<AppFlowyDatePicker> {
  late DateTime? _selectedDay = widget.selectedDay;
  late ReminderOption _selectedReminderOption = widget.selectedReminderOption;

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
          const _GroupSeparator(),
          ReminderSelector(
            mutex: widget.popoverMutex,
            selectedOption: _selectedReminderOption,
            onOptionSelected: (option) {
              setState(() => _selectedReminderOption = option);
              widget.onReminderSelected?.call(option);
            },
          ),
          if (widget.options?.isNotEmpty ?? false) ...[
            const _GroupSeparator(),
            ListView.separated(
              shrinkWrap: true,
              itemCount: widget.options!.length,
              separatorBuilder: (_, __) => const _GroupSeparator(),
              itemBuilder: (_, index) =>
                  _renderGroupOptions(widget.options![index].options),
            ),
          ],
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
}

class _GroupSeparator extends StatelessWidget {
  const _GroupSeparator();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(color: Theme.of(context).dividerColor, height: 1.0),
      );
}

import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_text_field.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/end_time_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/start_text_field.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

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
    this.startDay,
    this.endDay,
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
    this.allowFormatChanges = false,
    this.onDateFormatChanged,
    this.onTimeFormatChanged,
    this.onClearDate,
    this.onCalendarCreated,
    this.onPageChanged,
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

  /// Start date in selected range
  final DateTime? startDay;

  /// End date in selected range
  final DateTime? endDay;

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
  /// __Supported on Desktop & Web__
  ///
  final List<OptionGroup>? options;

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

  final void Function(PageController pageController)? onCalendarCreated;

  final void Function(DateTime focusedDay)? onPageChanged;

  @override
  State<AppFlowyDatePicker> createState() => _AppFlowyDatePickerState();
}

class _AppFlowyDatePickerState extends State<AppFlowyDatePicker> {
  late DateTime? _selectedDay = widget.selectedDay;
  late ReminderOption _selectedReminderOption = widget.selectedReminderOption;

  @override
  void didUpdateWidget(covariant AppFlowyDatePicker oldWidget) {
    _selectedDay = oldWidget.selectedDay != widget.selectedDay
        ? widget.selectedDay
        : _selectedDay;
    _selectedReminderOption =
        oldWidget.selectedReminderOption != widget.selectedReminderOption
            ? widget.selectedReminderOption
            : _selectedReminderOption;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) =>
      UniversalPlatform.isMobile ? buildMobilePicker() : buildDesktopPicker();

  Widget buildMobilePicker() {
    return DatePicker(
      isRange: widget.isRange,
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDaySelected?.call(selectedDay, focusedDay);

        if (widget.rebuildOnDaySelected) {
          setState(() => _selectedDay = selectedDay);
        }
      },
      onRangeSelected: widget.onRangeSelected,
      selectedDay:
          widget.rebuildOnDaySelected ? _selectedDay : widget.selectedDay,
      firstDay: widget.firstDay,
      lastDay: widget.lastDay,
      startDay: widget.startDay,
      endDay: widget.endDay,
      onCalendarCreated: widget.onCalendarCreated,
      onPageChanged: widget.onPageChanged,
    );
  }

  Widget buildDesktopPicker() {
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
              selectedDay: widget.rebuildOnDaySelected
                  ? _selectedDay
                  : widget.selectedDay,
              firstDay: widget.firstDay,
              lastDay: widget.lastDay,
              startDay: widget.startDay,
              endDay: widget.endDay,
              onCalendarCreated: widget.onCalendarCreated,
              onPageChanged: widget.onPageChanged,
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
            if (widget.onReminderSelected != null) ...[
              const _GroupSeparator(),
              ReminderSelector(
                mutex: widget.popoverMutex,
                hasTime: widget.includeTime,
                timeFormat: widget.timeFormat,
                selectedOption: _selectedReminderOption,
                onOptionSelected: (option) {
                  setState(() => _selectedReminderOption = option);
                  widget.onReminderSelected?.call(option);
                },
              ),
            ],
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

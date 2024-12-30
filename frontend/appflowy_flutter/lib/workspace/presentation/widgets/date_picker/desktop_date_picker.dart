import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'appflowy_date_picker_base.dart';
import 'widgets/date_picker.dart';
import 'widgets/date_time_text_field.dart';
import 'widgets/end_time_button.dart';
import 'widgets/reminder_selector.dart';

class OptionGroup {
  OptionGroup({required this.options});

  final List<Widget> options;
}

class DesktopAppFlowyDatePicker extends AppFlowyDatePicker {
  const DesktopAppFlowyDatePicker({
    super.key,
    required super.dateTime,
    super.endDateTime,
    required super.includeTime,
    required super.isRange,
    super.reminderOption = ReminderOption.none,
    required super.dateFormat,
    required super.timeFormat,
    super.onDaySelected,
    super.onRangeSelected,
    super.onIncludeTimeChanged,
    super.onIsRangeChanged,
    super.onReminderSelected,
    this.popoverMutex,
    this.options = const [],
  });

  final PopoverMutex? popoverMutex;

  final List<OptionGroup> options;

  @override
  State<AppFlowyDatePicker> createState() => DesktopAppFlowyDatePickerState();
}

@visibleForTesting
class DesktopAppFlowyDatePickerState
    extends AppFlowyDatePickerState<DesktopAppFlowyDatePicker> {
  final isTabPressedNotifier = ValueNotifier<bool>(false);
  final refreshStartTextFieldNotifier = RefreshDateTimeTextFieldController();
  final refreshEndTextFieldNotifier = RefreshDateTimeTextFieldController();

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
              showHint: true,
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
                showHint: isRange && !(dateTime != null && endDateTime == null),
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
                onChanged: onIsRangeChanged,
              ),
              const VSpace(4.0),
            ],
            if (widget.onIncludeTimeChanged != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IncludeTimeButton(
                  includeTime: includeTime,
                  onChanged: onIncludeTimeChanged,
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

  @override
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
      });
    } else {
      widget.onDaySelected?.call(value);

      setState(() {
        dateTime = value;
        focusedDateTime = getNewFocusedDay(value);
      });
    }
  }

  @override
  void onEndDateTimeInputSubmitted(DateTime value) {
    if (isRange) {
      if (endDateTime == null) {
        value = combineDateTimes(value, widget.endDateTime);
      }
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

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_option_decorate_box.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/date.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_editor.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'appflowy_date_picker_base.dart';

class MobileAppFlowyDatePicker extends AppFlowyDatePicker {
  const MobileAppFlowyDatePicker({
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
    this.onClearDate,
  });

  final VoidCallback? onClearDate;

  @override
  State<MobileAppFlowyDatePicker> createState() =>
      _MobileAppFlowyDatePickerState();
}

class _MobileAppFlowyDatePickerState
    extends AppFlowyDatePickerState<MobileAppFlowyDatePicker> {
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
            onStartTimeChanged: onDateTimeInputSubmitted,
            onEndTimeChanged: onEndDateTimeInputSubmitted,
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
            onRangeChanged: onIsRangeChanged,
          ),
        if (widget.onIncludeTimeChanged != null)
          _IncludeTimeSwitch(
            showTopBorder: widget.onIsRangeChanged == null,
            includeTime: includeTime,
            onIncludeTimeChanged: onIncludeTimeChanged,
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
          if (isRange) ...[
            VSpace(8.0, color: Theme.of(context).colorScheme.surface),
            _buildTime(
              context,
              endDateStr,
              endTimeStr,
              includeTime,
              false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTime(
    BuildContext context,
    String dateStr,
    String timeStr,
    bool includeTime,
    bool isStartDay,
  ) {
    final List<Widget> children = [];

    final now = DateTime.now();
    final hintDate = DateTime(now.year, now.month, 1, 9);

    if (!includeTime) {
      children.add(
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final result = await _showDateTimePicker(
                context,
                isStartDay ? dateTime : endDateTime,
                use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                mode: CupertinoDatePickerMode.date,
              );
              handleDateTimePickerResult(result, isStartDay);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: FlowyText(
                dateStr.isNotEmpty ? dateStr : getDateStr(hintDate),
                color: dateStr.isEmpty ? Theme.of(context).hintColor : null,
              ),
            ),
          ),
        ),
      );
    } else {
      children.addAll([
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final result = await _showDateTimePicker(
                context,
                isStartDay ? dateTime : endDateTime,
                use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                mode: CupertinoDatePickerMode.date,
              );
              handleDateTimePickerResult(result, isStartDay);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FlowyText(
                dateStr.isNotEmpty ? dateStr : "",
                textAlign: TextAlign.center,
              ),
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
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final result = await _showDateTimePicker(
                context,
                isStartDay ? dateTime : endDateTime,
                use24hFormat: timeFormat == TimeFormatPB.TwentyFourHour,
                mode: CupertinoDatePickerMode.time,
              );
              handleDateTimePickerResult(result, isStartDay);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FlowyText(
                timeStr.isNotEmpty ? timeStr : "",
                textAlign: TextAlign.center,
              ),
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
      child: Row(
        children: children,
      ),
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
    return DateFormat(dateFormat.pattern).format(dateTime);
  }

  String getTimeStr(DateTime? dateTime) {
    if (dateTime == null || !includeTime) {
      return "";
    }
    return DateFormat(timeFormat.pattern).format(dateTime);
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

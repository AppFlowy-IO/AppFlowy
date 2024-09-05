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
    this.selectedDay,
    this.startDay,
    this.endDay,
    this.dateStr,
    this.endDateStr,
    this.timeStr,
    this.endTimeStr,
    this.enableRanges = false,
    this.isRange = false,
    this.rebuildOnDaySelected = false,
    this.rebuildOnTimeChanged = false,
    required this.includeTime,
    required this.use24hFormat,
    required this.timeFormat,
    this.selectedReminderOption,
    required this.onStartTimeChanged,
    this.onEndTimeChanged,
    required this.onIncludeTimeChanged,
    this.onRangeChanged,
    this.onDaySelected,
    this.onRangeSelected,
    this.onClearDate,
    this.liveDateFormatter,
    this.onReminderSelected,
  });

  final DateTime? selectedDay;
  final DateTime? startDay;
  final DateTime? endDay;

  final String? dateStr;
  final String? endDateStr;
  final String? timeStr;
  final String? endTimeStr;

  final bool enableRanges;
  final bool isRange;
  final bool includeTime;
  final bool rebuildOnDaySelected;
  final bool rebuildOnTimeChanged;
  final bool use24hFormat;

  final TimeFormatPB timeFormat;

  final ReminderOption? selectedReminderOption;

  final Function(String? time) onStartTimeChanged;
  final Function(String? time)? onEndTimeChanged;
  final Function(bool) onIncludeTimeChanged;
  final Function(bool)? onRangeChanged;

  final DaySelectedCallback? onDaySelected;
  final RangeSelectedCallback? onRangeSelected;
  final VoidCallback? onClearDate;
  final OnReminderSelected? onReminderSelected;

  final String Function(DateTime)? liveDateFormatter;

  @override
  State<MobileAppFlowyDatePicker> createState() =>
      _MobileAppFlowyDatePickerState();
}

class _MobileAppFlowyDatePickerState extends State<MobileAppFlowyDatePicker> {
  late bool _includeTime = widget.includeTime;
  late String? _dateStr = widget.dateStr;
  late ReminderOption _reminderOption =
      widget.selectedReminderOption ?? ReminderOption.none;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyOptionDecorateBox(
          showTopBorder: false,
          child: _IncludeTimePicker(
            dateStr:
                widget.liveDateFormatter != null ? _dateStr : widget.dateStr,
            endDateStr: widget.endDateStr,
            timeStr: widget.timeStr,
            endTimeStr: widget.endTimeStr,
            includeTime: _includeTime,
            use24hFormat: widget.use24hFormat,
            onStartTimeChanged: widget.onStartTimeChanged,
            onEndTimeChanged: widget.onEndTimeChanged,
            rebuildOnTimeChanged: widget.rebuildOnTimeChanged,
          ),
        ),
        const _Divider(),
        FlowyOptionDecorateBox(
          child: MobileDatePicker(
            isRange: widget.isRange,
            selectedDay: widget.selectedDay,
            startDay: widget.startDay,
            endDay: widget.endDay,
            onDaySelected: (selected, focused) {
              widget.onDaySelected?.call(selected, focused);

              if (widget.liveDateFormatter != null) {
                setState(() => _dateStr = widget.liveDateFormatter!(selected));
              }
            },
            onRangeSelected: widget.onRangeSelected,
            rebuildOnDaySelected: widget.rebuildOnDaySelected,
          ),
        ),
        const _Divider(),
        if (widget.enableRanges && widget.onRangeChanged != null)
          _EndDateSwitch(
            isRange: widget.isRange,
            onRangeChanged: widget.onRangeChanged!,
          ),
        _IncludeTimeSwitch(
          showTopBorder: !widget.enableRanges || widget.onRangeChanged == null,
          includeTime: _includeTime,
          onIncludeTimeChanged: (includeTime) {
            widget.onIncludeTimeChanged(includeTime);
            setState(() => _includeTime = includeTime);
          },
        ),
        if (widget.onReminderSelected != null) ...[
          const _Divider(),
          _ReminderSelector(
            selectedReminderOption: _reminderOption,
            onReminderSelected: (option) {
              widget.onReminderSelected!.call(option);
              setState(() => _reminderOption = option);
            },
            timeFormat: widget.timeFormat,
            hasTime: widget.includeTime,
          ),
        ],
        if (widget.onClearDate != null) ...[
          const _Divider(),
          _ClearDateButton(onClearDate: widget.onClearDate!),
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

class _IncludeTimePicker extends StatefulWidget {
  const _IncludeTimePicker({
    required this.includeTime,
    this.dateStr,
    this.endDateStr,
    this.timeStr,
    this.endTimeStr,
    this.rebuildOnTimeChanged = false,
    required this.use24hFormat,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  final bool includeTime;

  final String? dateStr;
  final String? endDateStr;

  final String? timeStr;
  final String? endTimeStr;

  final bool rebuildOnTimeChanged;

  final bool use24hFormat;

  final Function(String? time) onStartTimeChanged;
  final Function(String? time)? onEndTimeChanged;

  @override
  State<_IncludeTimePicker> createState() => _IncludeTimePickerState();
}

class _IncludeTimePickerState extends State<_IncludeTimePicker> {
  late String? _timeStr = widget.timeStr;
  late String? _endTimeStr = widget.endTimeStr;

  @override
  Widget build(BuildContext context) {
    if (widget.dateStr == null || widget.dateStr!.isEmpty) {
      return const Divider(height: 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTime(
            context,
            widget.includeTime,
            widget.use24hFormat,
            true,
            widget.dateStr,
            widget.rebuildOnTimeChanged ? _timeStr : widget.timeStr,
          ),
          VSpace(8.0, color: Theme.of(context).colorScheme.surface),
          _buildTime(
            context,
            widget.includeTime,
            widget.use24hFormat,
            false,
            widget.endDateStr,
            widget.rebuildOnTimeChanged ? _endTimeStr : widget.endTimeStr,
          ),
        ],
      ),
    );
  }

  Widget _buildTime(
    BuildContext context,
    bool isIncludeTime,
    bool use24hFormat,
    bool isStartDay,
    String? dateStr,
    String? timeStr,
  ) {
    if (dateStr == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = [];

    if (!isIncludeTime) {
      children.addAll([
        const HSpace(12.0),
        FlowyText(dateStr),
      ]);
    } else {
      children.addAll([
        Expanded(child: FlowyText(dateStr, textAlign: TextAlign.center)),
        Container(width: 1, height: 16, color: Colors.grey),
        Expanded(
          child: GestureDetector(
            onTap: () => _showTimePicker(
              context,
              use24hFormat: use24hFormat,
              isStartDay: isStartDay,
            ),
            child: FlowyText(timeStr ?? '', textAlign: TextAlign.center),
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

  Future<void> _showTimePicker(
    BuildContext context, {
    required bool use24hFormat,
    required bool isStartDay,
  }) async {
    String? selectedTime = isStartDay ? _timeStr : _endTimeStr;
    final initialDateTime = selectedTime != null
        ? _convertTimeStringToDateTime(selectedTime)
        : null;

    return showMobileBottomSheet(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialDateTime,
              use24hFormat: use24hFormat,
              onDateTimeChanged: (dateTime) {
                selectedTime = use24hFormat
                    ? DateFormat('HH:mm').format(dateTime)
                    : DateFormat('hh:mm a').format(dateTime);
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
                if (isStartDay) {
                  widget.onStartTimeChanged(selectedTime);

                  if (widget.rebuildOnTimeChanged && mounted) {
                    setState(() => _timeStr = selectedTime);
                  }
                } else {
                  widget.onEndTimeChanged?.call(selectedTime);

                  if (widget.rebuildOnTimeChanged && mounted) {
                    setState(() => _endTimeStr = selectedTime);
                  }
                }

                Navigator.of(context).pop();
              },
            ),
          ),
          const VSpace(18.0),
        ],
      ),
    );
  }

  DateTime _convertTimeStringToDateTime(String timeString) {
    final DateTime now = DateTime.now();

    final List<String> timeParts = timeString.split(':');

    if (timeParts.length != 2) {
      return now;
    }

    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class _EndDateSwitch extends StatelessWidget {
  const _EndDateSwitch({
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

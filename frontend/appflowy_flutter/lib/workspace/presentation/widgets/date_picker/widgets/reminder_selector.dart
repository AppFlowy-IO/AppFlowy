import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/layout.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

typedef OnReminderSelected = void Function(ReminderOption option);

class ReminderSelector extends StatelessWidget {
  const ReminderSelector({
    super.key,
    required this.mutex,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.timeFormat,
    this.hasTime = false,
  });

  final PopoverMutex? mutex;
  final ReminderOption selectedOption;
  final OnReminderSelected? onOptionSelected;
  final TimeFormatPB timeFormat;
  final bool hasTime;

  @override
  Widget build(BuildContext context) {
    final options = ReminderOption.values.toList();
    if (selectedOption != ReminderOption.custom) {
      options.remove(ReminderOption.custom);
    }

    options.removeWhere(
      (o) => !o.timeExempt && (!hasTime ? !o.withoutTime : o.requiresNoTime),
    );

    final optionWidgets = options.map(
      (o) {
        String label = o.label;
        if (o.withoutTime && !o.timeExempt) {
          const time = "09:00";
          final t = timeFormat == TimeFormatPB.TwelveHour ? "$time AM" : time;

          label = "$label ($t)";
        }

        return SizedBox(
          height: DatePickerSize.itemHeight,
          child: FlowyButton(
            text: FlowyText.medium(label),
            rightIcon:
                o == selectedOption ? const FlowySvg(FlowySvgs.check_s) : null,
            onTap: () {
              if (o != selectedOption) {
                onOptionSelected?.call(o);
                mutex?.close();
              }
            },
          ),
        );
      },
    ).toList();

    return AppFlowyPopover(
      mutex: mutex,
      offset: const Offset(8, 0),
      margin: EdgeInsets.zero,
      constraints: const BoxConstraints(maxHeight: 400, maxWidth: 205),
      popupBuilder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: SeparatedColumn(
              children: optionWidgets,
              separatorBuilder: () => VSpace(DatePickerSize.seperatorHeight),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SizedBox(
          height: DatePickerSize.itemHeight,
          child: FlowyButton(
            text: FlowyText.medium(LocaleKeys.datePicker_reminderLabel.tr()),
            rightIcon: Row(
              children: [
                FlowyText.regular(selectedOption.label),
                const FlowySvg(FlowySvgs.more_s),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ReminderOption {
  none(time: Duration()),
  atTimeOfEvent(time: Duration()),
  fiveMinsBefore(time: Duration(minutes: 5)),
  tenMinsBefore(time: Duration(minutes: 10)),
  fifteenMinsBefore(time: Duration(minutes: 15)),
  thirtyMinsBefore(time: Duration(minutes: 30)),
  oneHourBefore(time: Duration(hours: 1)),
  twoHoursBefore(time: Duration(hours: 2)),
  onDayOfEvent(
    time: Duration(hours: 9),
    withoutTime: true,
    requiresNoTime: true,
  ),
  // 9:00 AM the day before (24-9)
  oneDayBefore(time: Duration(hours: 15), withoutTime: true),
  twoDaysBefore(time: Duration(days: 1, hours: 15), withoutTime: true),
  oneWeekBefore(time: Duration(days: 6, hours: 15), withoutTime: true),
  custom(time: Duration());

  const ReminderOption({
    required this.time,
    this.withoutTime = false,
    this.requiresNoTime = false,
  });

  final Duration time;
  final bool withoutTime;
  final bool requiresNoTime;

  bool get timeExempt =>
      [ReminderOption.none, ReminderOption.custom].contains(this);

  String get label => switch (this) {
        ReminderOption.none => LocaleKeys.datePicker_reminderOptions_none.tr(),
        ReminderOption.atTimeOfEvent =>
          LocaleKeys.datePicker_reminderOptions_atTimeOfEvent.tr(),
        ReminderOption.fiveMinsBefore =>
          LocaleKeys.datePicker_reminderOptions_fiveMinsBefore.tr(),
        ReminderOption.tenMinsBefore =>
          LocaleKeys.datePicker_reminderOptions_tenMinsBefore.tr(),
        ReminderOption.fifteenMinsBefore =>
          LocaleKeys.datePicker_reminderOptions_fifteenMinsBefore.tr(),
        ReminderOption.thirtyMinsBefore =>
          LocaleKeys.datePicker_reminderOptions_thirtyMinsBefore.tr(),
        ReminderOption.oneHourBefore =>
          LocaleKeys.datePicker_reminderOptions_oneHourBefore.tr(),
        ReminderOption.twoHoursBefore =>
          LocaleKeys.datePicker_reminderOptions_twoHoursBefore.tr(),
        ReminderOption.onDayOfEvent =>
          LocaleKeys.datePicker_reminderOptions_onDayOfEvent.tr(),
        ReminderOption.oneDayBefore =>
          LocaleKeys.datePicker_reminderOptions_oneDayBefore.tr(),
        ReminderOption.twoDaysBefore =>
          LocaleKeys.datePicker_reminderOptions_twoDaysBefore.tr(),
        ReminderOption.oneWeekBefore =>
          LocaleKeys.datePicker_reminderOptions_oneWeekBefore.tr(),
        ReminderOption.custom =>
          LocaleKeys.datePicker_reminderOptions_custom.tr(),
      };

  static ReminderOption fromDateDifference(
    DateTime eventDate,
    DateTime reminderDate,
  ) {
    final def = fromMinutes(eventDate.difference(reminderDate).inMinutes);
    if (def != ReminderOption.custom) {
      return def;
    }

    final diff = eventDate.withoutTime.difference(reminderDate).inMinutes;
    return fromMinutes(diff);
  }

  static ReminderOption fromMinutes(int minutes) => switch (minutes) {
        0 => ReminderOption.atTimeOfEvent,
        5 => ReminderOption.fiveMinsBefore,
        10 => ReminderOption.tenMinsBefore,
        15 => ReminderOption.fifteenMinsBefore,
        30 => ReminderOption.thirtyMinsBefore,
        60 => ReminderOption.oneHourBefore,
        120 => ReminderOption.twoHoursBefore,
        // Negative because Event Day Today + 940 minutes
        -540 => ReminderOption.onDayOfEvent,
        900 => ReminderOption.oneDayBefore,
        2340 => ReminderOption.twoDaysBefore,
        9540 => ReminderOption.oneWeekBefore,
        _ => ReminderOption.custom,
      };

  DateTime fromDate(DateTime date) => switch (withoutTime) {
        true => requiresNoTime
            ? date.withoutTime.add(time)
            : date.withoutTime.subtract(time),
        _ => date.subtract(time),
      };
}

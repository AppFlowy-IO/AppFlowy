import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/layout.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

typedef OnReminderSelected = void Function(ReminderOption option);

class ReminderSelector extends StatelessWidget {
  const ReminderSelector({
    super.key,
    required this.mutex,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  final PopoverMutex? mutex;
  final ReminderOption selectedOption;
  final OnReminderSelected? onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final options = ReminderOption.values.toList();
    if (selectedOption != ReminderOption.custom) {
      options.remove(ReminderOption.custom);
    }

    final optionWidgets = options
        .map(
          (o) => SizedBox(
            height: DatePickerSize.itemHeight,
            child: FlowyButton(
              text: FlowyText.medium(o.label),
              rightIcon: o == selectedOption
                  ? const FlowySvg(FlowySvgs.check_s)
                  : null,
              onTap: () {
                if (o != selectedOption) {
                  onOptionSelected?.call(o);
                  mutex?.close();
                }
              },
            ),
          ),
        )
        .toList();

    return AppFlowyPopover(
      mutex: mutex,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, -155),
      margin: EdgeInsets.zero,
      constraints: BoxConstraints.loose(const Size(150, 310)),
      popupBuilder: (_) => Padding(
        padding: const EdgeInsets.all(6.0),
        child: ListView.separated(
          itemCount: options.length,
          separatorBuilder: (_, __) => VSpace(DatePickerSize.seperatorHeight),
          itemBuilder: (_, index) => optionWidgets[index],
        ),
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
  oneDayBefore(time: Duration(days: 1)),
  twoDaysBefore(time: Duration(days: 2)),
  custom(time: Duration());

  const ReminderOption({required this.time});

  final Duration time;

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
        ReminderOption.oneDayBefore =>
          LocaleKeys.datePicker_reminderOptions_oneDayBefore.tr(),
        ReminderOption.twoDaysBefore =>
          LocaleKeys.datePicker_reminderOptions_twoDaysBefore.tr(),
        ReminderOption.custom =>
          LocaleKeys.datePicker_reminderOptions_custom.tr(),
      };
}

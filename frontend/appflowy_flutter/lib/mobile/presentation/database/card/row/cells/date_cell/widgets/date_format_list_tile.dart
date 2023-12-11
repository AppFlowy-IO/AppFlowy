import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DateFormatListTile extends StatelessWidget {
  const DateFormatListTile({
    super.key,
    required this.currentFormatStr,
    this.groupValue,
    this.onChanged,
  });

  final String currentFormatStr;

  /// The group value for the radio list tile.
  final DateFormatPB? groupValue;

  /// The Function for the radio list tile.
  final void Function(DateFormatPB?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return Row(
      children: [
        PropertyTitle(
          LocaleKeys.grid_field_dateFormat.tr(),
        ),
        const Spacer(),
        GestureDetector(
          child: Row(
            children: [
              Text(
                currentFormatStr,
                style: style.textTheme.titleMedium,
              ),
              const HSpace(4),
              Icon(
                Icons.arrow_forward_ios_sharp,
                color: style.hintColor,
              ),
            ],
          ),
          onTap: () => showFlowyMobileBottomSheet(
            context,
            title: LocaleKeys.grid_field_dateFormat.tr(),
            builder: (_) {
              return Column(
                children: [
                  _DateFormatRadioListTile(
                    title: LocaleKeys.grid_field_dateFormatLocal.tr(),
                    dateFormatPB: DateFormatPB.Local,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                  _DateFormatRadioListTile(
                    title: LocaleKeys.grid_field_dateFormatUS.tr(),
                    dateFormatPB: DateFormatPB.US,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                  _DateFormatRadioListTile(
                    title: LocaleKeys.grid_field_dateFormatISO.tr(),
                    dateFormatPB: DateFormatPB.ISO,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                  _DateFormatRadioListTile(
                    title: LocaleKeys.grid_field_dateFormatFriendly.tr(),
                    dateFormatPB: DateFormatPB.Friendly,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                  _DateFormatRadioListTile(
                    title: LocaleKeys.grid_field_dateFormatDayMonthYear.tr(),
                    dateFormatPB: DateFormatPB.DayMonthYear,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateFormatRadioListTile extends StatelessWidget {
  const _DateFormatRadioListTile({
    required this.title,
    required this.dateFormatPB,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final DateFormatPB dateFormatPB;
  final DateFormatPB? groupValue;
  final void Function(DateFormatPB?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return RadioListTile<DateFormatPB>(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        title,
        style: style.textTheme.bodyMedium?.copyWith(
          color: style.colorScheme.onSurface,
        ),
      ),
      groupValue: groupValue,
      value: dateFormatPB,
      onChanged: onChanged,
    );
  }
}

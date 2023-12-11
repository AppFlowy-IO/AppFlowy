import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TimeFormatListTile extends StatelessWidget {
  const TimeFormatListTile({
    super.key,
    required this.currentFormatStr,
    required this.groupValue,
    required this.onChanged,
  });

  final String currentFormatStr;

  /// The group value for the radio list tile.
  final TimeFormatPB? groupValue;

  /// The Function for the radio list tile.
  final void Function(TimeFormatPB?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return Row(
      children: [
        PropertyTitle(
          LocaleKeys.grid_field_timeFormat.tr(),
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
            title: LocaleKeys.grid_field_timeFormat.tr(),
            builder: (context) {
              return Column(
                children: [
                  _TimeFormatRadioListTile(
                    title: LocaleKeys.grid_field_timeFormatTwelveHour.tr(),
                    timeFormatPB: TimeFormatPB.TwelveHour,
                    groupValue: groupValue,
                    onChanged: (newFormat) {
                      onChanged?.call(newFormat);
                      context.pop();
                    },
                  ),
                  _TimeFormatRadioListTile(
                    title: LocaleKeys.grid_field_timeFormatTwentyFourHour.tr(),
                    timeFormatPB: TimeFormatPB.TwentyFourHour,
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

class _TimeFormatRadioListTile extends StatelessWidget {
  const _TimeFormatRadioListTile({
    required this.title,
    required this.timeFormatPB,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final TimeFormatPB timeFormatPB;
  final TimeFormatPB? groupValue;
  final void Function(TimeFormatPB?)? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return RadioListTile<TimeFormatPB>(
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
      value: timeFormatPB,
      onChanged: onChanged,
    );
  }
}

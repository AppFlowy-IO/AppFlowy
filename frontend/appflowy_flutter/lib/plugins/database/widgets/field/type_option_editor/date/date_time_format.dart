import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';

class IncludeTimeButton extends StatelessWidget {
  const IncludeTimeButton({
    super.key,
    required this.onChanged,
    required this.value,
  });

  final Function(bool value) onChanged;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: Padding(
        padding: GridSize.typeOptionContentInsets,
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.clock_alarm_s,
              color: Theme.of(context).iconTheme.color,
            ),
            const HSpace(6),
            FlowyText.medium(LocaleKeys.grid_field_includeTime.tr()),
            const Spacer(),
            Toggle(
              value: value,
              onChanged: onChanged,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

extension DateFormatExtension on DateFormatPB {
  String title() {
    switch (this) {
      case DateFormatPB.Friendly:
        return LocaleKeys.grid_field_dateFormatFriendly.tr();
      case DateFormatPB.ISO:
        return LocaleKeys.grid_field_dateFormatISO.tr();
      case DateFormatPB.Local:
        return LocaleKeys.grid_field_dateFormatLocal.tr();
      case DateFormatPB.US:
        return LocaleKeys.grid_field_dateFormatUS.tr();
      case DateFormatPB.DayMonthYear:
        return LocaleKeys.grid_field_dateFormatDayMonthYear.tr();
      default:
        throw UnimplementedError;
    }
  }
}

extension TimeFormatExtension on TimeFormatPB {
  String title() {
    switch (this) {
      case TimeFormatPB.TwelveHour:
        return LocaleKeys.grid_field_timeFormatTwelveHour.tr();
      case TimeFormatPB.TwentyFourHour:
        return LocaleKeys.grid_field_timeFormatTwentyFourHour.tr();
      default:
        throw UnimplementedError;
    }
  }
}

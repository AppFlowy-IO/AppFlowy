import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_time_settings.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class DateTypeOptionButton extends StatelessWidget {
  const DateTypeOptionButton({
    super.key,
    required this.dateFormat,
    required this.timeFormat,
    required this.onDateFormatChanged,
    required this.onTimeFormatChanged,
    required this.popoverMutex,
  });

  final DateFormatPB dateFormat;
  final TimeFormatPB timeFormat;
  final Function(DateFormatPB) onDateFormatChanged;
  final Function(TimeFormatPB) onTimeFormatChanged;
  final PopoverMutex? popoverMutex;

  @override
  Widget build(BuildContext context) {
    final title =
        "${LocaleKeys.datePicker_dateFormat.tr()} & ${LocaleKeys.datePicker_timeFormat.tr()}";
    return AppFlowyPopover(
      mutex: popoverMutex,
      offset: const Offset(8, 0),
      margin: EdgeInsets.zero,
      constraints: BoxConstraints.loose(const Size(140, 100)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            text: FlowyText.medium(title),
            rightIcon: const FlowySvg(FlowySvgs.more_s),
          ),
        ),
      ),
      popupBuilder: (_) => DateTimeSetting(
        dateFormat: dateFormat,
        timeFormat: timeFormat,
        onDateFormatChanged: (format) {
          onDateFormatChanged(format);
          popoverMutex?.close();
        },
        onTimeFormatChanged: (format) {
          onTimeFormatChanged(format);
          popoverMutex?.close();
        },
      ),
    );
  }
}

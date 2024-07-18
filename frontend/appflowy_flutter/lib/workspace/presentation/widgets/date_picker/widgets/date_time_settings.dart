import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/util.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/layout.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class DateTimeSetting extends StatefulWidget {
  const DateTimeSetting({
    super.key,
    required this.dateFormat,
    required this.timeFormat,
    required this.onDateFormatChanged,
    required this.onTimeFormatChanged,
  });

  final DateFormatPB dateFormat;
  final TimeFormatPB timeFormat;
  final Function(DateFormatPB) onDateFormatChanged;
  final Function(TimeFormatPB) onTimeFormatChanged;

  @override
  State<DateTimeSetting> createState() => _DateTimeSettingState();
}

class _DateTimeSettingState extends State<DateTimeSetting> {
  final timeSettingPopoverMutex = PopoverMutex();
  String? overlayIdentifier;

  @override
  void dispose() {
    timeSettingPopoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(8, 0),
        popupBuilder: (_) => TypeOptionList(
          options: {for (final v in DateFormatPB.values) v.title(): v},
          selectedOption: widget.dateFormat,
          onSelected: _onDateFormatChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TypeOptionButton(text: LocaleKeys.grid_field_dateFormat.tr()),
        ),
      ),
      AppFlowyPopover(
        mutex: timeSettingPopoverMutex,
        triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
        offset: const Offset(8, 0),
        popupBuilder: (_) => TypeOptionList(
          options: {for (final v in TimeFormatPB.values) v.title(): v},
          selectedOption: widget.timeFormat,
          onSelected: _onTimeFormatChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TypeOptionButton(text: LocaleKeys.grid_field_timeFormat.tr()),
        ),
      ),
    ];

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (_, __) => VSpace(DatePickerSize.seperatorHeight),
        itemCount: children.length,
        itemBuilder: (_, int index) => children[index],
        padding: const EdgeInsets.symmetric(vertical: 6.0),
      ),
    );
  }

  void _onTimeFormatChanged(TimeFormatPB format) {
    widget.onTimeFormatChanged(format);
    timeSettingPopoverMutex.close();
  }

  void _onDateFormatChanged(DateFormatPB format) {
    widget.onDateFormatChanged(format);
    timeSettingPopoverMutex.close();
  }
}

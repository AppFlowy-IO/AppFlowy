import 'package:appflowy/workspace/presentation/widgets/date_picker/utils/layout.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class IncludeTimeButton extends StatelessWidget {
  const IncludeTimeButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DatePickerSize.itemHeight,
      child: Padding(
        padding: DatePickerSize.itemOptionInsets,
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.clock_alarm_s,
              color: Theme.of(context).iconTheme.color,
            ),
            const HSpace(6),
            FlowyText.medium(LocaleKeys.datePicker_includeTime.tr()),
            const Spacer(),
            Toggle(
              value: value,
              onChanged: onChanged,
              style: ToggleStyle.big,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

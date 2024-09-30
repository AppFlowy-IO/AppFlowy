import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class EndTimeButton extends StatelessWidget {
  const EndTimeButton({
    super.key,
    required this.isRange,
    required this.onChanged,
  });

  final bool isRange;
  final Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: Padding(
          padding: GridSize.typeOptionContentInsets,
          child: Row(
            children: [
              FlowySvg(
                FlowySvgs.date_s,
                color: Theme.of(context).iconTheme.color,
              ),
              const HSpace(6),
              FlowyText(LocaleKeys.datePicker_isRange.tr()),
              const Spacer(),
              Toggle(
                value: isRange,
                onChanged: onChanged,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

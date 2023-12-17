import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

@visibleForTesting
class ClearDateButton extends StatelessWidget {
  const ClearDateButton({
    super.key,
    required this.onClearDate,
  });

  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FlowyButton(
          text: FlowyText.medium(LocaleKeys.grid_field_clearDate.tr()),
          onTap: () {
            onClearDate();
            PopoverContainer.of(context).close();
          },
        ),
      ),
    );
  }
}

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class SharedSectionEmpty extends StatelessWidget {
  const SharedSectionEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlowySvg(
            FlowySvgs.empty_shared_section_m,
            color: theme.iconColorScheme.tertiary,
          ),
          const VSpace(12),
          Text(
            LocaleKeys.shareTab_nothingSharedWithYou.tr(),
            style: theme.textStyle.heading3.enhanced(
              color: theme.textColorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const VSpace(4),
          Text(
            LocaleKeys.shareTab_pagesSharedWithYouWillShowHere.tr(),
            style: theme.textStyle.heading4.standard(
              color: theme.textColorScheme.tertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const VSpace(kBottomNavigationBarHeight + 60.0),
        ],
      ),
    );
  }
}

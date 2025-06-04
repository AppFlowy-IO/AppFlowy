import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class MSharedSectionHeader extends StatelessWidget {
  const MSharedSectionHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const HSpace(HomeSpaceViewSizes.mHorizontalPadding),
          FlowySvg(
            FlowySvgs.shared_with_me_m,
            color: theme.badgeColorScheme.color13Thick2,
          ),
          const HSpace(10.0),
          FlowyText.medium(
            LocaleKeys.shareSection_shared.tr(),
            lineHeight: 1.15,
            fontSize: 16.0,
          ),
          const HSpace(HomeSpaceViewSizes.mHorizontalPadding),
        ],
      ),
    );
  }
}

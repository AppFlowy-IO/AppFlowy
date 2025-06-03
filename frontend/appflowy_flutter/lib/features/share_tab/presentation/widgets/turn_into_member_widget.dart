import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TurnIntoMemberWidget extends StatelessWidget {
  const TurnIntoMemberWidget({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return FlowyTooltip(
      message: LocaleKeys.shareTab_turnIntoMember.tr(),
      child: AFGhostButton.normal(
        onTap: onTap,
        padding: EdgeInsets.all(theme.spacing.s),
        builder: (context, isHovering, disabled) {
          return FlowySvg(FlowySvgs.turn_into_member_m);
        },
      ),
    );
  }
}

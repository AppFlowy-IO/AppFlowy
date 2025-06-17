import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ProfileInviteButton extends StatelessWidget {
  const ProfileInviteButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return AFOutlinedButton.normal(
      onTap: onTap,
      builder: (context, isHovering, disabled) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.mention_invite_user_m,
            size: Size.square(20),
            color: theme.iconColorScheme.primary,
            blendMode: null,
          ),
          HSpace(spacing.s),
          Text(
            LocaleKeys.document_mentionMenu_invite.tr(),
            style: TextStyle(
              color: AppFlowyTheme.of(context).textColorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

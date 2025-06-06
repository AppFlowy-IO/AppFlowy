import 'package:appflowy/features/share_tab/logic/share_tab_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpgradeToProWidget extends StatelessWidget {
  const UpgradeToProWidget({
    super.key,
    required this.onUpgrade,
    required this.onClose,
  });

  final VoidCallback onClose;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Color(0x129327ff),
        borderRadius: BorderRadius.circular(theme.borderRadius.m),
      ),
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.m,
        horizontal: theme.spacing.l,
      ),
      margin: EdgeInsets.only(
        top: theme.spacing.l,
      ),
      child: Row(
        children: [
          FlowySvg(
            FlowySvgs.upgrade_pro_crown_m,
            blendMode: null,
          ),
          HSpace(
            theme.spacing.m,
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: LocaleKeys.shareTab_upgrade.tr(),
                  style: theme.textStyle.caption.standard().copyWith(
                        color: theme.textColorScheme.featured,
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      onUpgrade();
                    },
                  mouseCursor: SystemMouseCursors.click,
                ),
                TextSpan(
                  text: LocaleKeys.shareTab_toProPlanToInviteGuests.tr(),
                  style: theme.textStyle.caption.standard().copyWith(
                        color: theme.textColorScheme.featured,
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AFGhostButton.normal(
            size: AFButtonSize.s,
            padding: EdgeInsets.all(theme.spacing.xs),
            onTap: () {
              context
                  .read<ShareTabBloc>()
                  .add(ShareTabEvent.upgradeToProClicked());
              onClose();
            },
            builder: (context, isHovering, disabled) => FlowySvg(
              FlowySvgs.upgrade_to_pro_close_m,
              size: const Size.square(20),
            ),
          ),
        ],
      ),
    );
  }
}

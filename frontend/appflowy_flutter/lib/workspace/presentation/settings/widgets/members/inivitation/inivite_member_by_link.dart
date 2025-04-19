import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class InviteMemberByLink extends StatelessWidget {
  const InviteMemberByLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(),
            _Description(),
          ],
        ),
        Spacer(),
        _CopyLinkButton(),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      LocaleKeys.settings_appearance_members_inviteLinkToAddMember.tr(),
      style: theme.textStyle.body.enhanced(
        color: theme.textColorScheme.primary,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: LocaleKeys.settings_appearance_members_clickToCopyLink.tr(),
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.primary,
            ),
          ),
          TextSpan(
            text: ' ${LocaleKeys.settings_appearance_members_or.tr()} ',
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.primary,
            ),
          ),
          TextSpan(
            text: LocaleKeys.settings_appearance_members_generateANewLink.tr(),
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.action,
            ),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // todo: generate new link
              },
          ),
        ],
      ),
    );
  }
}

class _CopyLinkButton extends StatelessWidget {
  const _CopyLinkButton();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFOutlinedTextButton.normal(
      text: LocaleKeys.button_copyLink.tr(),
      textStyle: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.l,
        vertical: theme.spacing.s,
      ),
      onTap: () {
        // todo: copy link
      },
    );
  }
}

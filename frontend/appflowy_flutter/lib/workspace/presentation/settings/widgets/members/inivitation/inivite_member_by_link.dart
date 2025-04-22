import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              ..onTap = () => _onGenerateInviteLink(context),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerateInviteLink(BuildContext context) async {
    final inviteLink = context.read<WorkspaceMemberBloc>().state.inviteLink;
    if (inviteLink != null) {
      // show a dialog to confirm if the user wants to copy the link to the clipboard
      await showConfirmDialog(
        context: context,
        style: ConfirmPopupStyle.cancelAndOk,
        title: 'Reset the invite link?',
        description:
            'Resetting will deactivate the current link for all space members and generate a new one. The old link will no longer be available.',
        confirmLabel: 'Reset',
        onConfirm: () {
          context.read<WorkspaceMemberBloc>().add(
                const WorkspaceMemberEvent.generateInviteLink(),
              );
        },
        confirmButtonBuilder: (_) => AFFilledTextButton.destructive(
          text: 'Reset',
          onTap: () {
            context.read<WorkspaceMemberBloc>().add(
                  const WorkspaceMemberEvent.generateInviteLink(),
                );

            Navigator.of(context).pop();
          },
        ),
      );
    } else {
      context.read<WorkspaceMemberBloc>().add(
            const WorkspaceMemberEvent.generateInviteLink(),
          );
    }
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
        final link = context.read<WorkspaceMemberBloc>().state.inviteLink;
        if (link != null) {
          getIt<ClipboardService>().setData(
            ClipboardServiceData(
              plainText: link,
            ),
          );

          showToastNotification(
            message: LocaleKeys.document_inlineLink_copyLink.tr(),
          );
        } else {
          showToastNotification(
            message: 'You haven\'t generated an invite link yet.',
            type: ToastificationType.error,
          );
        }
      },
    );
  }
}

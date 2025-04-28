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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Title(),
              _Description(),
            ],
          ),
        ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    final state = context.read<WorkspaceMemberBloc>().state;
    final inviteLink = state.inviteLink;

    // check the current workspace member count, if it exceed the limit, show a upgrade dialog.
    // prevent hard code here, because the member count may exceed the limit after the invite link is generated.
    if (inviteLink == null && state.members.length >= 3) {
      await showConfirmDialog(
        context: context,
        title:
            LocaleKeys.settings_appearance_members_inviteFailedDialogTitle.tr(),
        description:
            LocaleKeys.settings_appearance_members_inviteFailedMemberLimit.tr(),
        confirmLabel: LocaleKeys
            .settings_appearance_members_memberLimitExceededUpgrade
            .tr(),
        onConfirm: () => context
            .read<WorkspaceMemberBloc>()
            .add(const WorkspaceMemberEvent.upgradePlan()),
      );
      return;
    }

    if (inviteLink != null) {
      // show a dialog to confirm if the user wants to copy the link to the clipboard
      await showConfirmDialog(
        context: context,
        style: ConfirmPopupStyle.cancelAndOk,
        title: LocaleKeys.settings_appearance_members_resetInviteLink.tr(),
        description: LocaleKeys
            .settings_appearance_members_resetInviteLinkDescription
            .tr(),
        confirmLabel: LocaleKeys.settings_appearance_members_reset.tr(),
        onConfirm: () {
          context.read<WorkspaceMemberBloc>().add(
                const WorkspaceMemberEvent.generateInviteLink(),
              );
        },
        confirmButtonBuilder: (_) => AFFilledTextButton.destructive(
          text: LocaleKeys.settings_appearance_members_reset.tr(),
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

class _CopyLinkButton extends StatefulWidget {
  const _CopyLinkButton();

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  ToastificationItem? toastificationItem;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFOutlinedTextButton.normal(
      text: LocaleKeys.settings_appearance_members_copyLink.tr(),
      textStyle: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.l,
        vertical: theme.spacing.s,
      ),
      onTap: () async {
        final state = context.read<WorkspaceMemberBloc>().state;
        // check the current workspace member count, if it exceed the limit, show a upgrade dialog.
        // prevent hard code here, because the member count may exceed the limit after the invite link is generated.
        if (state.members.length >= 3) {
          await showConfirmDialog(
            context: context,
            title: LocaleKeys
                .settings_appearance_members_inviteFailedDialogTitle
                .tr(),
            description: LocaleKeys
                .settings_appearance_members_inviteFailedMemberLimit
                .tr(),
            confirmLabel: LocaleKeys
                .settings_appearance_members_memberLimitExceededUpgrade
                .tr(),
            onConfirm: () => context
                .read<WorkspaceMemberBloc>()
                .add(const WorkspaceMemberEvent.upgradePlan()),
          );
          return;
        }

        final link = state.inviteLink;
        if (link != null) {
          await getIt<ClipboardService>().setData(
            ClipboardServiceData(
              plainText: link,
            ),
          );

          if (toastificationItem != null) {
            toastification.dismiss(toastificationItem!);
          }

          toastificationItem = showToastNotification(
            message: LocaleKeys.shareAction_copyLinkSuccess.tr(),
          );
        } else {
          showToastNotification(
            message: LocaleKeys.settings_appearance_members_noInviteLink.tr(),
            type: ToastificationType.error,
          );
        }
      },
    );
  }
}

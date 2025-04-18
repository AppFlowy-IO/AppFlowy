import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class InviteMemberByLink extends StatefulWidget {
  const InviteMemberByLink({super.key});

  @override
  State<InviteMemberByLink> createState() => _InviteMemberByLinkState();
}

class _InviteMemberByLinkState extends State<InviteMemberByLink> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.settings_appearance_members_inviteMemberByEmail.tr(),
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        VSpace(theme.spacing.m),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AFTextField(
                controller: _emailController,
                hintText:
                    LocaleKeys.settings_appearance_members_inviteHint.tr(),
                onSubmitted: (value) => _inviteMember(),
              ),
            ),
            HSpace(theme.spacing.l),
            AFFilledTextButton.primary(
              text: LocaleKeys.settings_appearance_members_sendInvite.tr(),
              onTap: _inviteMember,
            ),
          ],
        ),
      ],
    );
  }

  void _inviteMember() {
    final email = _emailController.text;
    if (!isEmail(email)) {
      showToastNotification(
        type: ToastificationType.error,
        message: LocaleKeys.settings_appearance_members_emailInvalidError.tr(),
      );
      return;
    }

    context
        .read<WorkspaceMemberBloc>()
        .add(WorkspaceMemberEvent.inviteWorkspaceMember(email));
    // clear the email field after inviting
    _emailController.clear();
  }
}

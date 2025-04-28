import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class MInviteMemberByEmail extends StatefulWidget {
  const MInviteMemberByEmail({super.key});

  @override
  State<MInviteMemberByEmail> createState() => _MInviteMemberByEmailState();
}

class _MInviteMemberByEmailState extends State<MInviteMemberByEmail> {
  final _emailController = TextEditingController();

  bool _isInviteButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(_onEmailChanged);
  }

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
        AFTextField(
          autoFocus: true,
          controller: _emailController,
          hintText: LocaleKeys.settings_appearance_members_inviteHint.tr(),
          onSubmitted: (value) => _inviteMember(),
        ),
        VSpace(theme.spacing.m),
        _isInviteButtonEnabled
            ? AFFilledTextButton.primary(
                text: 'Send invite',
                alignment: Alignment.center,
                size: AFButtonSize.l,
                textStyle: theme.textStyle.heading4.enhanced(
                  color: theme.textColorScheme.onFill,
                ),
                onTap: _inviteMember,
              )
            : AFFilledTextButton.disabled(
                text: 'Send invite',
                alignment: Alignment.center,
                size: AFButtonSize.l,
                textStyle: theme.textStyle.heading4.enhanced(
                  color: theme.textColorScheme.tertiary,
                ),
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
        .add(WorkspaceMemberEvent.inviteWorkspaceMemberByEmail(email));
    // clear the email field after inviting
    _emailController.clear();
  }

  void _onEmailChanged() {
    setState(() {
      _isInviteButtonEnabled = _emailController.text.isNotEmpty;
    });
  }
}

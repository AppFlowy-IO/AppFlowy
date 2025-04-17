import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/password/password_bloc.dart';
import 'package:appflowy/user/application/prelude.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email_and_password.dart';
import 'package:appflowy/util/navigator_context_extension.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/password/change_password.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/password/setup_password.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_third_party_login.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountSignInOutSection extends StatelessWidget {
  const AccountSignInOutSection({
    super.key,
    required this.userProfile,
    required this.onAction,
    this.signIn = true,
  });

  final UserProfilePB userProfile;
  final VoidCallback onAction;
  final bool signIn;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      children: [
        Text(
          LocaleKeys.settings_accountPage_login_title.tr(),
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        const Spacer(),
        AccountSignInOutButton(
          userProfile: userProfile,
          onAction: onAction,
          signIn: signIn,
        ),
      ],
    );
  }
}

class AccountSignInOutButton extends StatelessWidget {
  const AccountSignInOutButton({
    super.key,
    required this.userProfile,
    required this.onAction,
    this.signIn = true,
  });

  final UserProfilePB userProfile;
  final VoidCallback onAction;
  final bool signIn;

  @override
  Widget build(BuildContext context) {
    return AFFilledTextButton.primary(
      text: signIn
          ? LocaleKeys.settings_accountPage_login_loginLabel.tr()
          : LocaleKeys.settings_accountPage_login_logoutLabel.tr(),
      onTap: () =>
          signIn ? _showSignInDialog(context) : _showLogoutDialog(context),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showConfirmDialog(
      context: context,
      title: LocaleKeys.settings_accountPage_login_logoutLabel.tr(),
      description: userProfile.encryptionType == EncryptionTypePB.Symmetric
          ? LocaleKeys.settings_menu_selfEncryptionLogoutPrompt.tr()
          : LocaleKeys.settings_menu_logoutPrompt.tr(),
      onConfirm: () async {
        await getIt<AuthService>().signOut();
        onAction();
      },
    );
  }

  Future<void> _showSignInDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => BlocProvider<SignInBloc>(
        create: (context) => getIt<SignInBloc>(),
        child: const FlowyDialog(
          constraints: BoxConstraints(maxHeight: 485, maxWidth: 375),
          child: _SignInDialogContent(),
        ),
      ),
    );
  }
}

class ChangePasswordSection extends StatelessWidget {
  const ChangePasswordSection({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocBuilder<PasswordBloc, PasswordState>(
      builder: (context, state) {
        return Row(
          children: [
            Text(
              'Password',
              style: theme.textStyle.body.enhanced(
                color: theme.textColorScheme.primary,
              ),
            ),
            const Spacer(),
            state.hasPassword
                ? AFFilledTextButton.primary(
                    text: 'Change password',
                    onTap: () => _showChangePasswordDialog(context),
                  )
                : AFFilledTextButton.primary(
                    text: 'Set password',
                    onTap: () => _showSetPasswordDialog(context),
                  ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final theme = AppFlowyTheme.of(context);
    await showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<PasswordBloc>.value(
            value: context.read<PasswordBloc>(),
          ),
          BlocProvider<SignInBloc>.value(
            value: getIt<SignInBloc>(),
          ),
        ],
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.borderRadius.xl),
          ),
          child: ChangePasswordDialogContent(
            userProfile: userProfile,
          ),
        ),
      ),
    );
  }

  Future<void> _showSetPasswordDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<PasswordBloc>.value(
            value: context.read<PasswordBloc>(),
          ),
          BlocProvider<SignInBloc>.value(
            value: getIt<SignInBloc>(),
          ),
        ],
        child: Dialog(
          child: SetupPasswordDialogContent(
            userProfile: userProfile,
          ),
        ),
      ),
    );
  }
}

class _SignInDialogContent extends StatelessWidget {
  const _SignInDialogContent();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const _DialogHeader(),
                const _DialogTitle(),
                const VSpace(16),
                const ContinueWithEmailAndPassword(),
                if (isAuthEnabled) ...[
                  const VSpace(20),
                  const _OrDivider(),
                  const VSpace(10),
                  SettingThirdPartyLogin(
                    didLogin: () {
                      context.popToHome();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBackButton(context),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: Navigator.of(context).pop,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            const FlowySvg(FlowySvgs.arrow_back_m, size: Size.square(24)),
            const HSpace(8),
            FlowyText.semibold(LocaleKeys.button_back.tr(), fontSize: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: Navigator.of(context).pop,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: FlowySvg(
          FlowySvgs.m_close_m,
          size: const Size.square(20),
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FlowyText.medium(
            LocaleKeys.settings_accountPage_login_loginLabel.tr(),
            fontSize: 22,
            color: Theme.of(context).colorScheme.tertiary,
            maxLines: null,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FlowyText.regular(LocaleKeys.signIn_or.tr()),
        ),
        const Flexible(child: Divider(thickness: 1)),
      ],
    );
  }
}

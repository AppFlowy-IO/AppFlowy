import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/prelude.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email_and_password.dart';
import 'package:appflowy/util/navigator_context_extension.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_third_party_login.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
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
    return Row(
      children: [
        Text(
          'Password',
          style: theme.textStyle.body.enhanced(
            color: theme.textColorScheme.primary,
          ),
        ),
        const Spacer(),
        AFFilledTextButton.primary(
          text: 'Change password',
          onTap: () => _showChangePasswordDialog(context),
        ),
      ],
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => BlocProvider<SignInBloc>(
        create: (context) => getIt<SignInBloc>(),
        child: Dialog(
          child: _ChangePasswordDialogContent(
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

class _ChangePasswordDialogContent extends StatefulWidget {
  const _ChangePasswordDialogContent({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<_ChangePasswordDialogContent> createState() =>
      _ChangePasswordDialogContentState();
}

class _ChangePasswordDialogContentState
    extends State<_ChangePasswordDialogContent> {
  final currentPasswordTextFieldKey = GlobalKey<AFTextFieldState>();
  final newPasswordTextFieldKey = GlobalKey<AFTextFieldState>();
  final confirmPasswordTextFieldKey = GlobalKey<AFTextFieldState>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final iconSize = 20.0;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          VSpace(theme.spacing.l),
          ..._buildCurrentPasswordFields(context),
          VSpace(theme.spacing.m),
          ..._buildNewPasswordFields(context),
          VSpace(theme.spacing.m),
          ..._buildConfirmPasswordFields(context),
          VSpace(theme.spacing.l),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Change password',
          style: theme.textStyle.heading.h4(
            color: theme.textColorScheme.primary,
          ),
        ),
        const Spacer(),
        AFGhostButton.normal(
          size: AFButtonSize.s,
          padding: EdgeInsets.all(theme.spacing.xs),
          onTap: () => Navigator.of(context).pop(),
          builder: (context, isHovering, disabled) => FlowySvg(
            FlowySvgs.password_close_m,
            size: const Size.square(20),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCurrentPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        'Current password',
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: currentPasswordTextFieldKey,
        controller: currentPasswordController,
        hintText: 'Enter your current password',
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => _buildSuffixIcon(
          context,
          isObscured: isObscured,
          onTap: () {
            currentPasswordTextFieldKey.currentState?.syncObscured(!isObscured);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildNewPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        'New password',
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: newPasswordTextFieldKey,
        controller: newPasswordController,
        hintText: 'Enter your new password',
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => _buildSuffixIcon(
          context,
          isObscured: isObscured,
          onTap: () {
            newPasswordTextFieldKey.currentState?.syncObscured(!isObscured);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildConfirmPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        'Confirm password',
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: confirmPasswordTextFieldKey,
        controller: confirmPasswordController,
        hintText: 'Confirm your new password',
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => _buildSuffixIcon(
          context,
          isObscured: isObscured,
          onTap: () {
            confirmPasswordTextFieldKey.currentState?.syncObscured(!isObscured);
          },
        ),
      ),
    ];
  }

  Widget _buildSubmitButton(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AFOutlinedTextButton.normal(
          text: 'Cancel',
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
            weight: FontWeight.w400,
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
        const HSpace(16),
        AFFilledTextButton.primary(
          text: 'Save',
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.onFill,
            weight: FontWeight.w400,
          ),
          onTap: () => _save(context),
        ),
      ],
    );
  }

  Widget _buildSuffixIcon(
    BuildContext context, {
    required bool isObscured,
    required VoidCallback onTap,
  }) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(right: theme.spacing.m),
      child: GestureDetector(
        onTap: onTap,
        child: FlowySvg(
          isObscured ? FlowySvgs.show_s : FlowySvgs.hide_s,
          color: theme.textColorScheme.secondary,
          size: const Size.square(20),
        ),
      ),
    );
  }

  void _save(BuildContext context) async {
    _resetError();

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty) {
      newPasswordTextFieldKey.currentState
          ?.syncError(errorText: 'New password is required');
    } else if (confirmPassword.isEmpty) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Confirm password is required',
      );
    } else if (newPassword != confirmPassword) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Passwords do not match',
      );
    } else if (newPassword == currentPassword) {
      newPasswordTextFieldKey.currentState?.syncError(
        errorText: 'New password cannot be the same as the current password',
      );
    }

    // all the verification passed, save the new password
    final userService = UserBackendService(userId: widget.userProfile.id);
    final result = await userService.updateUserProfile(
      password: newPassword,
    );

    result.fold(
      (userProfile) {
        showToastNotification(
          message: 'Password changed',
          description: 'Your password has been changed',
        );
        Navigator.of(context).pop();
      },
      (error) {
        showToastNotification(
          type: ToastificationType.error,
          message: 'Failed to change password',
          description: error.msg,
        );

        Log.error(error);
      },
    );
  }

  void _resetError() {
    currentPasswordTextFieldKey.currentState?.clearError();
    newPasswordTextFieldKey.currentState?.clearError();
    confirmPasswordTextFieldKey.currentState?.clearError();
  }
}

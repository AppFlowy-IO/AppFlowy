import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/password/password_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/password/password_suffix_icon.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetupPasswordDialogContent extends StatefulWidget {
  const SetupPasswordDialogContent({
    super.key,
    required this.userProfile,
    this.showCloseAndSaveButton = true,
    this.showSaveButton = false,
    this.showTitle = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final UserProfilePB userProfile;

  // display the desktop style close and save button
  final bool showCloseAndSaveButton;

  // display the mobile style save button
  final bool showSaveButton;

  // display the title
  final bool showTitle;

  // padding
  final EdgeInsets padding;

  @override
  State<SetupPasswordDialogContent> createState() =>
      _SetupPasswordDialogContentState();
}

class _SetupPasswordDialogContentState
    extends State<SetupPasswordDialogContent> {
  final passwordTextFieldKey = GlobalKey<AFTextFieldState>();
  final confirmPasswordTextFieldKey = GlobalKey<AFTextFieldState>();

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final iconSize = 20.0;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocListener<PasswordBloc, PasswordState>(
      listener: _onPasswordStateChanged,
      child: Container(
        padding: widget.padding,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              _buildTitle(context),
              VSpace(theme.spacing.xl),
            ],
            ..._buildPasswordFields(context),
            VSpace(theme.spacing.xl),
            ..._buildConfirmPasswordFields(context),
            VSpace(theme.spacing.xl),
            if (widget.showCloseAndSaveButton) ...[
              _buildSubmitButton(context),
            ],
            if (widget.showSaveButton) ...[
              _buildSaveButton(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LocaleKeys.newSettings_myAccount_password_setupPassword.tr(),
          style: theme.textStyle.heading4.prominent(
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

  List<Widget> _buildPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        LocaleKeys.newSettings_myAccount_password_title.tr(),
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: passwordTextFieldKey,
        controller: passwordController,
        hintText: LocaleKeys
            .newSettings_myAccount_password_hint_confirmYourPassword
            .tr(),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => PasswordSuffixIcon(
          isObscured: isObscured,
          onTap: () {
            passwordTextFieldKey.currentState?.syncObscured(!isObscured);
          },
        ),
      ),
    ];
  }

  List<Widget> _buildConfirmPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        LocaleKeys.newSettings_myAccount_password_confirmPassword.tr(),
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: confirmPasswordTextFieldKey,
        controller: confirmPasswordController,
        hintText: LocaleKeys
            .newSettings_myAccount_password_hint_confirmYourPassword
            .tr(),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => PasswordSuffixIcon(
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
          text: LocaleKeys.button_cancel.tr(),
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
            weight: FontWeight.w400,
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
        HSpace(theme.spacing.l),
        AFFilledTextButton.primary(
          text: LocaleKeys.button_save.tr(),
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.onFill,
            weight: FontWeight.w400,
          ),
          onTap: () => _save(context),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFFilledTextButton.primary(
      text: LocaleKeys.button_save.tr(),
      textStyle: theme.textStyle.body.standard(
        color: theme.textColorScheme.onFill,
      ),
      size: AFButtonSize.l,
      alignment: Alignment.center,
      onTap: () => _save(context),
    );
  }

  void _save(BuildContext context) async {
    _resetError();

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      passwordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_newPasswordIsRequired
            .tr(),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_confirmPasswordIsRequired
            .tr(),
      );
      return;
    }

    if (password != confirmPassword) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_passwordsDoNotMatch
            .tr(),
      );
      return;
    }

    // all the verification passed, save the password
    context.read<PasswordBloc>().add(
          PasswordEvent.setupPassword(
            newPassword: password,
          ),
        );
  }

  void _resetError() {
    passwordTextFieldKey.currentState?.clearError();
    confirmPasswordTextFieldKey.currentState?.clearError();
  }

  void _onPasswordStateChanged(BuildContext context, PasswordState state) {
    bool hasError = false;
    String message = '';
    String description = '';

    final setPasswordResult = state.setupPasswordResult;

    if (setPasswordResult != null) {
      setPasswordResult.fold(
        (success) {
          message = LocaleKeys
              .newSettings_myAccount_password_toast_passwordSetupSuccessfully
              .tr();
        },
        (error) {
          hasError = true;
          message = LocaleKeys
              .newSettings_myAccount_password_toast_passwordSetupFailed
              .tr();
          description = error.msg;
        },
      );
    }

    if (!state.isSubmitting && message.isNotEmpty) {
      showToastNotification(
        message: message,
        description: description,
        type: hasError ? ToastificationType.error : ToastificationType.success,
      );

      if (!hasError) {
        Navigator.of(context).pop();
      }
    }
  }
}

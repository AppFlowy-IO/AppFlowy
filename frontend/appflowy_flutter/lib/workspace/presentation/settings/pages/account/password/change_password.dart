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

class ChangePasswordDialogContent extends StatefulWidget {
  const ChangePasswordDialogContent({
    super.key,
    required this.userProfile,
    this.showTitle = true,
    this.showCloseAndSaveButton = true,
    this.showSaveButton = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final UserProfilePB userProfile;

  // display the title
  final bool showTitle;

  // display the desktop style close and save button
  final bool showCloseAndSaveButton;

  // display the mobile style save button
  final bool showSaveButton;

  final EdgeInsets padding;

  @override
  State<ChangePasswordDialogContent> createState() =>
      _ChangePasswordDialogContentState();
}

class _ChangePasswordDialogContentState
    extends State<ChangePasswordDialogContent> {
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
            ..._buildCurrentPasswordFields(context),
            VSpace(theme.spacing.xl),
            ..._buildNewPasswordFields(context),
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
          LocaleKeys.newSettings_myAccount_password_changePassword.tr(),
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

  List<Widget> _buildCurrentPasswordFields(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return [
      Text(
        LocaleKeys.newSettings_myAccount_password_currentPassword.tr(),
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: currentPasswordTextFieldKey,
        controller: currentPasswordController,
        hintText: LocaleKeys
            .newSettings_myAccount_password_hint_enterYourCurrentPassword
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
        LocaleKeys.newSettings_myAccount_password_newPassword.tr(),
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: newPasswordTextFieldKey,
        controller: newPasswordController,
        hintText: LocaleKeys
            .newSettings_myAccount_password_hint_enterYourNewPassword
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
        LocaleKeys.newSettings_myAccount_password_confirmNewPassword.tr(),
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: confirmPasswordTextFieldKey,
        controller: confirmPasswordController,
        hintText: LocaleKeys
            .newSettings_myAccount_password_hint_confirmYourNewPassword
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

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      currentPasswordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_currentPasswordIsRequired
            .tr(),
      );
      return;
    }

    if (newPassword.isEmpty) {
      newPasswordTextFieldKey.currentState?.syncError(
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

    if (newPassword != confirmPassword) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_passwordsDoNotMatch
            .tr(),
      );
      return;
    }

    if (newPassword == currentPassword) {
      newPasswordTextFieldKey.currentState?.syncError(
        errorText: LocaleKeys
            .newSettings_myAccount_password_error_newPasswordIsSameAsCurrent
            .tr(),
      );
      return;
    }

    // all the verification passed, save the new password
    context.read<PasswordBloc>().add(
          PasswordEvent.changePassword(
            oldPassword: currentPassword,
            newPassword: newPassword,
          ),
        );
  }

  void _resetError() {
    currentPasswordTextFieldKey.currentState?.clearError();
    newPasswordTextFieldKey.currentState?.clearError();
    confirmPasswordTextFieldKey.currentState?.clearError();
  }

  void _onPasswordStateChanged(BuildContext context, PasswordState state) {
    bool hasError = false;
    String message = '';

    final changePasswordResult = state.changePasswordResult;
    final setPasswordResult = state.setupPasswordResult;

    if (changePasswordResult != null) {
      changePasswordResult.fold(
        (success) {
          message = LocaleKeys
              .newSettings_myAccount_password_toast_passwordUpdatedSuccessfully
              .tr();
        },
        (error) {
          hasError = true;
          message = LocaleKeys
              .newSettings_myAccount_password_toast_passwordUpdatedFailed
              .tr();
        },
      );
    } else if (setPasswordResult != null) {
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
        },
      );
    }

    if (!state.isSubmitting && message.isNotEmpty) {
      showToastNotification(
        message: message,
        type: hasError ? ToastificationType.error : ToastificationType.success,
      );

      if (!hasError) {
        Navigator.of(context).pop();
      }
    }
  }
}

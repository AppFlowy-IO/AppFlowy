import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/user/application/password/password_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChangePasswordDialogContent extends StatefulWidget {
  const ChangePasswordDialogContent({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(context),
            VSpace(theme.spacing.l),
            ..._buildCurrentPasswordFields(context),
            VSpace(theme.spacing.l),
            ..._buildNewPasswordFields(context),
            VSpace(theme.spacing.l),
            ..._buildConfirmPasswordFields(context),
            VSpace(theme.spacing.l),
            _buildSubmitButton(context),
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
          'Change password',
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
      return;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Confirm password is required',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Passwords do not match',
      );
      return;
    }

    if (newPassword == currentPassword) {
      newPasswordTextFieldKey.currentState?.syncError(
        errorText: 'New password cannot be the same as the current password',
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
    String description = '';

    final changePasswordResult = state.changePasswordResult;
    final setPasswordResult = state.setupPasswordResult;

    if (changePasswordResult != null) {
      changePasswordResult.fold(
        (success) {
          message = 'Password changed';
          description = 'Your password has been changed';
        },
        (error) {
          hasError = true;
          message = 'Failed to change password';
          description = error.msg;
        },
      );
    } else if (setPasswordResult != null) {
      setPasswordResult.fold(
        (success) {
          message = 'Password set';
          description = 'Your password has been set';
        },
        (error) {
          hasError = true;
          message = 'Failed to set password';
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
    }
  }
}

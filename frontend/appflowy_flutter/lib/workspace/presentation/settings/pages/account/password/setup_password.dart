import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/user/application/password/password_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetupPasswordDialogContent extends StatefulWidget {
  const SetupPasswordDialogContent({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(context),
            VSpace(theme.spacing.l),
            ..._buildPasswordFields(context),
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
          'Setup password',
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
        'Password',
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: passwordTextFieldKey,
        controller: passwordController,
        hintText: 'Enter your password',
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        suffixIconConstraints: BoxConstraints.tightFor(
          width: iconSize + theme.spacing.m,
          height: iconSize,
        ),
        suffixIconBuilder: (context, isObscured) => _buildSuffixIcon(
          context,
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
        'Confirm password',
        style: theme.textStyle.caption.enhanced(
          color: theme.textColorScheme.secondary,
        ),
      ),
      VSpace(theme.spacing.xs),
      AFTextField(
        key: confirmPasswordTextFieldKey,
        controller: confirmPasswordController,
        hintText: 'Confirm your password',
        keyboardType: TextInputType.visiblePassword,
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

    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      passwordTextFieldKey.currentState?.syncError(
        errorText: 'Password is required',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Confirm password is required',
      );
      return;
    }

    if (password != confirmPassword) {
      confirmPasswordTextFieldKey.currentState?.syncError(
        errorText: 'Passwords do not match',
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

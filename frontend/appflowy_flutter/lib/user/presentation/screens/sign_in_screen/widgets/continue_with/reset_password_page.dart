import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/reset_password.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/set_new_password.dart';
import 'package:flutter/material.dart';

enum ResetPasswordPageState {
  enterPasscode,
  setNewPassword,
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.backToLogin,
    required this.email,
    required this.baseUrl,
  });

  final String email;
  final VoidCallback backToLogin;
  final String baseUrl;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  ResetPasswordPageState state = ResetPasswordPageState.enterPasscode;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ResetPasswordPageState.enterPasscode => ResetPasswordWidget(
          email: widget.email,
          backToLogin: widget.backToLogin,
          baseUrl: widget.baseUrl,
          onValidateResetPasswordToken: (isValid) {
            setState(() {
              state = ResetPasswordPageState.setNewPassword;
            });
          },
        ),
      ResetPasswordPageState.setNewPassword => SetNewPasswordWidget(
          backToLogin: widget.backToLogin,
          email: widget.email,
        ),
    };
  }
}

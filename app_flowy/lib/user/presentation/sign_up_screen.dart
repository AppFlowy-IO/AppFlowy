import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_up_bloc.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/image.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignUpBloc>(),
      child: BlocListener<SignUpBloc, SignUpState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (result) => _handleSuccessOrFail(result, context),
          );
        },
        child: const Scaffold(
          body: SignUpForm(),
        ),
      ),
    );
  }

  void _handleSuccessOrFail(
      Either<UserProfile, UserError> result, BuildContext context) {
    result.fold(
      (user) => {
        // router.showWorkspaceSelectScreen(context, user)
      },
      (error) => _showErrorMessage(context, error.msg),
    );
  }

  void _showErrorMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }
}

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AuthFormContainer(
        children: [
          const AuthFormTitle(
            title: 'Sign Up to Appflowy',
            logoSize: Size(60, 60),
          ),
          const VSpace(30),
          const EmailTextField(),
          const PasswordTextField(),
          const PasswordTextField(hintText: "Repeate password"),
          const VSpace(30),
          const SignUpButton(),
          const VSpace(10),
          const SignUpPrompt(),
          if (context.read<SignUpBloc>().state.isSubmitting) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: null),
          ]
        ],
      ),
    );
  }
}

class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Row(
      children: [
        Text("Already have an account",
            style: TextStyle(color: theme.shader3, fontSize: 12)),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Sign In',
            style: TextStyle(color: theme.main1),
          ),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return RoundedTextButton(
      title: 'Get Started',
      height: 48,
      borderRadius: BorderRadius.circular(10),
      color: theme.main1,
      press: () {
        context
            .read<SignUpBloc>()
            .add(const SignUpEvent.signUpWithUserEmailAndPassword());
      },
    );
  }
}

class PasswordTextField extends StatelessWidget {
  final String hintText;
  const PasswordTextField({
    Key? key,
    this.hintText = "Password",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: svgWidgetWithName("home/Hide.svg"),
          obscureHideIcon: svgWidgetWithName("home/Show.svg"),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          hintText: hintText,
          normalBorderColor: theme.shader4,
          highlightBorderColor: theme.red,
          errorText: context
              .read<SignUpBloc>()
              .state
              .passwordError
              .fold(() => "", (error) => error),
          onChanged: (value) => context
              .read<SignUpBloc>()
              .add(SignUpEvent.passwordChanged(value)),
        );
      },
    );
  }
}

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: 'Email',
          normalBorderColor: theme.shader4,
          highlightBorderColor: theme.red,
          errorText: context
              .read<SignUpBloc>()
              .state
              .emailError
              .fold(() => "", (error) => error),
          onChanged: (value) =>
              context.read<SignUpBloc>().add(SignUpEvent.emailChanged(value)),
        );
      },
    );
  }
}

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_up_bloc.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/image.dart';

class SignUpScreen extends StatelessWidget {
  final IAuthRouter router;
  const SignUpScreen({Key? key, required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignUpBloc>(),
      child: BlocListener<SignUpBloc, SignUpState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => {},
            (result) => _handleSuccessOrFail(context, result),
          );
        },
        child: const Scaffold(body: SignUpForm()),
      ),
    );
  }

  void _handleSuccessOrFail(BuildContext context, Either<UserProfile, UserError> result) {
    result.fold(
      (user) => router.pushWelcomeScreen(context, user),
      (error) => showSnapBar(context, error.msg),
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
          const FlowyLogoTitle(
            title: 'Sign Up to Appflowy',
            logoSize: Size(60, 60),
          ),
          const VSpace(30),
          const EmailTextField(),
          const PasswordTextField(),
          const RepeatPasswordTextField(),
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
        Text(
          "Already have an account?",
          style: TextStyle(color: theme.shader3, fontSize: 12),
        ),
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
          onPressed: () => Navigator.pop(context),
          child: Text('Sign In', style: TextStyle(color: theme.main1)),
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
      color: theme.main1,
      onPressed: () {
        context.read<SignUpBloc>().add(const SignUpEvent.signUpWithUserEmailAndPassword());
      },
    );
  }
}

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) => previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: svg("home/hide"),
          obscureHideIcon: svg("home/show"),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          hintText: "Password",
          normalBorderColor: theme.shader4,
          highlightBorderColor: theme.red,
          cursorColor: theme.main1,
          errorText: context.read<SignUpBloc>().state.passwordError.fold(() => "", (error) => error),
          onChanged: (value) => context.read<SignUpBloc>().add(SignUpEvent.passwordChanged(value)),
        );
      },
    );
  }
}

class RepeatPasswordTextField extends StatelessWidget {
  const RepeatPasswordTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) => previous.repeatPasswordError != current.repeatPasswordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: svg("home/hide"),
          obscureHideIcon: svg("home/show"),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          hintText: "Repeate password",
          normalBorderColor: theme.shader4,
          highlightBorderColor: theme.red,
          cursorColor: theme.main1,
          errorText: context.read<SignUpBloc>().state.repeatPasswordError.fold(() => "", (error) => error),
          onChanged: (value) => context.read<SignUpBloc>().add(SignUpEvent.repeatPasswordChanged(value)),
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
      buildWhen: (previous, current) => previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: 'Email',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          normalBorderColor: theme.shader4,
          highlightBorderColor: theme.red,
          cursorColor: theme.main1,
          errorText: context.read<SignUpBloc>().state.emailError.fold(() => "", (error) => error),
          onChanged: (value) => context.read<SignUpBloc>().add(SignUpEvent.emailChanged(value)),
        );
      },
    );
  }
}

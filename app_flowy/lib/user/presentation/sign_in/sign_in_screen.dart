import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_in/sign_in_bloc.dart';
import 'package:app_flowy/user/domain/i_auth.dart';
import 'package:app_flowy/user/presentation/sign_in/widgets/background.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class SignInScreen extends StatelessWidget {
  final IAuthRouter router;
  const SignInScreen({Key? key, required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocListener<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (result) => _handleSuccessOrFail(result, context),
          );
        },
        child: Scaffold(
          body: SignInForm(router: router),
        ),
      ),
    );
  }

  void _handleSuccessOrFail(
      Either<UserDetail, UserError> result, BuildContext context) {
    result.fold(
      (user) => router.showHomeScreen(context, user),
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

class SignInForm extends StatelessWidget {
  final IAuthRouter router;
  const SignInForm({
    Key? key,
    required this.router,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SignInFormContainer(
        children: [
          const SignInTitle(
            title: 'Login to Appflowy',
            logoSize: Size(60, 60),
          ),
          const VSpace(30),
          const EmailTextField(),
          const PasswordTextField(),
          ForgetPasswordButton(router: router),
          const LoginButton(),
          const VSpace(10),
          SignUpPrompt(router: router),
          if (context.read<SignInBloc>().state.isSubmitting) ...[
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
    required this.router,
  }) : super(key: key);

  final IAuthRouter router;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text("Dont't have an account",
            style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: () => router.showSignUpScreen(context),
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.lightBlue),
          ),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedTextButton(
      title: 'Login',
      height: 45,
      borderRadius: BorderRadius.circular(10),
      color: Colors.lightBlue,
      press: () {
        context
            .read<SignInBloc>()
            .add(const SignInEvent.signedInWithUserEmailAndPassword());
      },
    );
  }
}

class ForgetPasswordButton extends StatelessWidget {
  const ForgetPasswordButton({
    Key? key,
    required this.router,
  }) : super(key: key);

  final IAuthRouter router;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: () => router.showForgetPasswordScreen(context),
      child: const Text(
        'Forgot Password?',
        style: TextStyle(color: Colors.lightBlue),
      ),
    );
  }
}

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      buildWhen: (previous, current) =>
          previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          hintText: 'password',
          normalBorderColor: Colors.green,
          highlightBorderColor: Colors.red,
          errorText: context
              .read<SignInBloc>()
              .state
              .passwordError
              .fold(() => "", (error) => error),
          onChanged: (value) => context
              .read<SignInBloc>()
              .add(SignInEvent.passwordChanged(value)),
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
    return BlocBuilder<SignInBloc, SignInState>(
      buildWhen: (previous, current) =>
          previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: 'email',
          normalBorderColor: Colors.green,
          highlightBorderColor: Colors.red,
          errorText: context
              .read<SignInBloc>()
              .state
              .emailError
              .fold(() => "", (error) => error),
          onChanged: (value) =>
              context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
        );
      },
    );
  }
}

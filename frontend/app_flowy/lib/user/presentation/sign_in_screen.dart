import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_in_bloc.dart';
import 'package:app_flowy/user/infrastructure/router.dart';
import 'package:app_flowy/user/presentation/widgets/background.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/image.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class SignInScreen extends StatelessWidget {
  final AuthRouter router;
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

  void _handleSuccessOrFail(Either<UserProfile, FlowyError> result, BuildContext context) {
    result.fold(
      (user) => router.pushWelcomeScreen(context, user),
      (error) => showSnapBar(context, error.msg),
    );
  }
}

class SignInForm extends StatelessWidget {
  final AuthRouter router;
  const SignInForm({
    Key? key,
    required this.router,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AuthFormContainer(
        children: [
          FlowyLogoTitle(
            title: LocaleKeys.signIn_loginTitle.tr(),
            logoSize: const Size(60, 60),
          ),
          const VSpace(30),
          const EmailTextField(),
          const PasswordTextField(),
          ForgetPasswordButton(router: router),
          const VSpace(30),
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

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(LocaleKeys.signIn_dontHaveAnAccount.tr(), style: Theme.of(context).textTheme.subtitle2),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.subtitle1,
          ),
          onPressed: () => router.pushSignUpScreen(context),
          child: Text(
            LocaleKeys.signUp_buttonText.tr(),
            style: TextStyle(color: Theme.of(context).primaryColor),
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
      title: LocaleKeys.signIn_loginButtonText.tr(),
      height: 48,
      borderRadius: Corners.s10Border,
      color: Theme.of(context).primaryColor,
      onPressed: () {
        context.read<SignInBloc>().add(const SignInEvent.signedInWithUserEmailAndPassword());
      },
    );
  }
}

class ForgetPasswordButton extends StatelessWidget {
  const ForgetPasswordButton({
    Key? key,
    required this.router,
  }) : super(key: key);

  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: () => router.pushForgetPasswordScreen(context),
      child: Text(
        LocaleKeys.signIn_forgotPassword.tr(),
        style: TextStyle(color: Theme.of(context).primaryColor),
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
      buildWhen: (previous, current) => previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          obscureIcon: svg("home/hide"),
          obscureHideIcon: svg("home/show"),
          hintText: LocaleKeys.signIn_passwordHint.tr(),
          normalBorderColor: Colors.transparent,
          highlightBorderColor: Theme.of(context).primaryColor,
          cursorColor: Theme.of(context).primaryColor,
          errorText: context.read<SignInBloc>().state.passwordError.fold(() => "", (error) => error),
          onChanged: (value) => context.read<SignInBloc>().add(SignInEvent.passwordChanged(value)),
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
      buildWhen: (previous, current) => previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: LocaleKeys.signIn_emailHint.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          normalBorderColor: Colors.transparent,
          highlightBorderColor: Theme.of(context).primaryColor,
          cursorColor: Theme.of(context).primaryColor,
          errorText: context.read<SignInBloc>().state.emailError.fold(() => "", (error) => error),
          onChanged: (value) => context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
        );
      },
    );
  }
}

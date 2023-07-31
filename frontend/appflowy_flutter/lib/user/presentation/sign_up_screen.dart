import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_up_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/widgets/background.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/image.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({
    super.key,
    required this.router,
  });

  final AuthRouter router;

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

  void _handleSuccessOrFail(
    BuildContext context,
    Either<UserProfilePB, FlowyError> result,
  ) {
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
          FlowyLogoTitle(
            title: LocaleKeys.signUp_title.tr(),
            logoSize: const Size(60, 60),
          ),
          const VSpace(30),
          const EmailTextField(),
          const VSpace(5),
          const PasswordTextField(),
          const VSpace(5),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FlowyText.medium(
          LocaleKeys.signUp_alreadyHaveAnAccount.tr(),
          color: Theme.of(context).hintColor,
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          onPressed: () => Navigator.pop(context),
          child: FlowyText.medium(
            LocaleKeys.signIn_buttonText.tr(),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class SignUpButton extends StatelessWidget {
  const SignUpButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedTextButton(
      title: LocaleKeys.signUp_getStartedText.tr(),
      height: 48,
      onPressed: () {
        context
            .read<SignUpBloc>()
            .add(const SignUpEvent.signUpWithUserEmailAndPassword());
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
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.passwordError != current.passwordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: svgWidget("home/hide"),
          obscureHideIcon: svgWidget("home/show"),
          hintText: LocaleKeys.signUp_passwordHint.tr(),
          normalBorderColor: Theme.of(context).colorScheme.outline,
          errorBorderColor: Theme.of(context).colorScheme.error,
          cursorColor: Theme.of(context).colorScheme.primary,
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

class RepeatPasswordTextField extends StatelessWidget {
  const RepeatPasswordTextField({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.repeatPasswordError != current.repeatPasswordError,
      builder: (context, state) {
        return RoundedInputField(
          obscureText: true,
          obscureIcon: svgWidget("home/hide"),
          obscureHideIcon: svgWidget("home/show"),
          hintText: LocaleKeys.signUp_repeatPasswordHint.tr(),
          normalBorderColor: Theme.of(context).colorScheme.outline,
          errorBorderColor: Theme.of(context).colorScheme.error,
          cursorColor: Theme.of(context).colorScheme.primary,
          errorText: context
              .read<SignUpBloc>()
              .state
              .repeatPasswordError
              .fold(() => "", (error) => error),
          onChanged: (value) => context
              .read<SignUpBloc>()
              .add(SignUpEvent.repeatPasswordChanged(value)),
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
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.emailError != current.emailError,
      builder: (context, state) {
        return RoundedInputField(
          hintText: LocaleKeys.signUp_emailHint.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          normalBorderColor: Theme.of(context).colorScheme.outline,
          errorBorderColor: Theme.of(context).colorScheme.error,
          cursorColor: Theme.of(context).colorScheme.primary,
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

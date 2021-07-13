import 'package:app_flowy/home/presentation/home_screen.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_in/sign_in_bloc.dart';
import 'package:app_flowy/user/presentation/sign_in/widgets/background.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: const SignInBackground(
        child: SignInForm(),
      ),
    );
  }
}

class SignInForm extends StatelessWidget {
  const SignInForm({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listenWhen: (p, c) => p != c,
      listener: (context, state) {
        state.signInFailure.fold(
          () {},
          (result) => _handleStateErrors(result, context),
        );
      },
      builder: (context, state) {
        return SignInFormBackground(
          children: [
            const SizedBox(height: 30),
            RoundedInputField(
              icon: Icons.person,
              hintText: 'email',
              onChanged: (value) => context
                  .read<SignInBloc>()
                  .add(SignInEvent.emailChanged(value)),
            ),
            RoundedInputField(
              icon: Icons.lock,
              obscureText: true,
              hintText: 'password',
              onChanged: (value) => context
                  .read<SignInBloc>()
                  .add(SignInEvent.passwordChanged(value)),
            ),
            RoundedButton(
              title: 'LOGIN',
              press: () {
                context
                    .read<SignInBloc>()
                    .add(const SignInEvent.signedInWithUserEmailAndPassword());
              },
            ),
            if (state.isSubmitting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(value: null),
            ]
          ],
        );
      },
    );
  }

  void _handleStateErrors(
      Either<UserDetail, UserError> some, BuildContext context) {
    some.fold(
      (userDetail) => showHomeScreen(context, userDetail),
      (result) => _showErrorMessage(context, result.msg),
    );
  }

  void _showErrorMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

  void showHomeScreen(BuildContext context, UserDetail userDetail) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HomeScreen(userDetail);
        },
      ),
    );
  }
}

class SignInFormBackground extends StatelessWidget {
  final List<Widget> children;
  const SignInFormBackground({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width * 0.4,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: children),
      ),
    );
  }
}

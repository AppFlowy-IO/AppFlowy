import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/sign_in/sign_in_bloc.dart';
import 'package:app_flowy/user/presentation/sign_in/widgets/background.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_detail.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: Scaffold(
        body: BlocProvider(
          create: (context) => getIt<SignInBloc>(),
          child: BlocConsumer<SignInBloc, SignInState>(
            listenWhen: (p, c) => p != c,
            listener: (context, state) {
              state.signInFailure.fold(
                () {},
                (result) => _handleStateErrors(result, context),
              );
            },
            builder: (context, state) => const SignInForm(),
          ),
        ),
      ),
    );
  }

  void _handleStateErrors(
      Either<UserDetail, UserError> some, BuildContext context) {
    some.fold(
      (userDetail) => _showHomeScreen(context, userDetail),
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

  void _showHomeScreen(BuildContext context, UserDetail userDetail) {
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

class SignInForm extends StatelessWidget {
  const SignInForm({
    Key? key,
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
          RoundedInputField(
            hintText: 'email',
            onChanged: (value) =>
                context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
          ),
          RoundedInputField(
            obscureText: true,
            hintText: 'password',
            onChanged: (value) => context
                .read<SignInBloc>()
                .add(SignInEvent.passwordChanged(value)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _showForgetPasswordScreen(context),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(color: Colors.lightBlue),
            ),
          ),
          RoundedButton(
            title: 'Login',
            height: 60,
            borderRadius: BorderRadius.circular(10),
            color: Colors.lightBlue,
            press: () {
              context
                  .read<SignInBloc>()
                  .add(const SignInEvent.signedInWithUserEmailAndPassword());
            },
          ),
          const VSpace(10),
          Row(
            children: [
              const Text("Dont't have an account",
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {},
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Colors.lightBlue),
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          if (context.read<SignInBloc>().state.isSubmitting) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: null),
          ]
        ],
      ),
    );
  }

  void _showForgetPasswordScreen(BuildContext context) {
    throw UnimplementedError();
  }
}

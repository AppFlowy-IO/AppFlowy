import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DesktopSignInScreen extends StatelessWidget {
  const DesktopSignInScreen({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const indicatorMinHeight = 4.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size(double.infinity, 60),
        child: MoveWindowDetector(),
      ),
      body: Center(
        child: AuthFormContainer(
          children: [
            FlowyLogoTitle(
              title: LocaleKeys.welcomeText.tr(),
              logoSize: const Size(60, 60),
            ),
            const VSpace(30),
            // Email and password. don't support yet.
            /*
          ...[
            const EmailTextField(),
            const VSpace(5),
            const PasswordTextField(),
            const VSpace(20),
            const LoginButton(),
            const VSpace(10),
      
            const VSpace(10),
            SignUpPrompt(router: router),
          ],
          */

            const SignInAnonymousButton(),

            // third-party sign in.
            const VSpace(20),

            if (isAuthEnabled) ...[
              const _OrDivider(),
              const VSpace(10),
              const ThirdPartySignInButtons(),
            ],
            const VSpace(20),
            // loading status
            const VSpace(indicatorMinHeight),
            isLoading
                ? const LinearProgressIndicator(
                    minHeight: indicatorMinHeight,
                  )
                : const VSpace(indicatorMinHeight),
            // add the same space when there's no loading status.
            // ConstrainedBox(
            //   constraints: const BoxConstraints(maxHeight: 140),
            //   child: HistoricalUserList(
            //     didOpenUser: () async {
            //       await FlowyRunner.run(
            //         FlowyApp(),
            //         integrationEnv(),
            //       );
            //     },
            //   ),
            // ),
            const VSpace(20),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(
          child: Divider(
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FlowyText.regular(LocaleKeys.signIn_or.tr()),
        ),
        const Flexible(
          child: Divider(
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

// The following code is migrated from previous signInScreen.dart(for desktop)
// We may need this later when sign up&in feature is ready
// class SignUpPrompt extends StatelessWidget {
//   const SignUpPrompt({
//     super.key,
//     required this.router,
//   }) ;

//   final AuthRouter router;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         FlowyText.medium(
//           LocaleKeys.signIn_dontHaveAnAccount.tr(),
//           color: Theme.of(context).hintColor,
//         ),
//         TextButton(
//           style: TextButton.styleFrom(
//             textStyle: Theme.of(context).textTheme.bodyMedium,
//           ),
//           onPressed: () => router.pushSignUpScreen(context),
//           child: Text(
//             LocaleKeys.signUp_buttonText.tr(),
//             style: TextStyle(color: Theme.of(context).colorScheme.primary),
//           ),
//         ),
//         ForgetPasswordButton(router: router),
//       ],
//     );
//   }
// }

// class LoginButton extends StatelessWidget {
//   const LoginButton({
//     super.key
//   }) ;

//   @override
//   Widget build(BuildContext context) {
//     return RoundedTextButton(
//       title: LocaleKeys.signIn_loginButtonText.tr(),
//       height: 48,
//       borderRadius: Corners.s10Border,
//       onPressed: () => context
//           .read<SignInBloc>()
//           .add(const SignInEvent.signedInWithUserEmailAndPassword()),
//     );
//   }
// }
// class ForgetPasswordButton extends StatelessWidget {
//   const ForgetPasswordButton({
//     super.key
//     required this.router,
//   }) ;

//   final AuthRouter router;

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       style: TextButton.styleFrom(
//         textStyle: Theme.of(context).textTheme.bodyMedium,
//       ),
//       onPressed: () {
//         throw UnimplementedError();
//       },
//       child: Text(
//         LocaleKeys.signIn_forgotPassword.tr(),
//         style: TextStyle(color: Theme.of(context).colorScheme.primary),
//       ),
//     );
//   }
// }

// class PasswordTextField extends StatelessWidget {
//   const PasswordTextField({
//     super.key
//   }) ;

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SignInBloc, SignInState>(
//       buildWhen: (previous, current) =>
//           previous.passwordError != current.passwordError,
//       builder: (context, state) {
//         return RoundedInputField(
//           obscureText: true,
//           obscureIcon: const FlowySvg(FlowySvgs.hide_m),
//           obscureHideIcon: const FlowySvg(FlowySvgs.show_m),
//           hintText: LocaleKeys.signIn_passwordHint.tr(),
//           errorText: context
//               .read<SignInBloc>()
//               .state
//               .passwordError
//               .fold(() => "", (error) => error),
//           onChanged: (value) => context
//               .read<SignInBloc>()
//               .add(SignInEvent.passwordChanged(value)),
//         );
//       },
//     );
//   }
// }

// class EmailTextField extends StatelessWidget {
//   const EmailTextField({
//     super.key
//   }) ;

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SignInBloc, SignInState>(
//       buildWhen: (previous, current) =>
//           previous.emailError != current.emailError,
//       builder: (context, state) {
//         return RoundedInputField(
//           hintText: LocaleKeys.signIn_emailHint.tr(),
//           errorText: context
//               .read<SignInBloc>()
//               .state
//               .emailError
//               .fold(() => "", (error) => error),
//           onChanged: (value) =>
//               context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
//         );
//       },
//     );
//   }
// }

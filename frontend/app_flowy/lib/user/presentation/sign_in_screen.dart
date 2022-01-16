// import 'package:app_flowy/startup/startup.dart';
// import 'package:app_flowy/user/application/sign_in_bloc.dart';
// import 'package:app_flowy/user/domain/i_auth.dart';
// import 'package:app_flowy/user/presentation/widgets/background.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
// import 'package:flowy_infra_ui/widget/spacing.dart';
// import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
// import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
// import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:dartz/dartz.dart';
// import 'package:flowy_infra/image.dart';
// import 'package:app_flowy/generated/locale_keys.g.dart';

// class SignInScreen extends StatelessWidget {
//   final IAuthRouter router;
//   const SignInScreen({Key? key, required this.router}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) => getIt<SignInBloc>(),
//       child: BlocListener<SignInBloc, SignInState>(
//         listener: (context, state) {
//           state.successOrFail.fold(
//             () => null,
//             (result) => _handleSuccessOrFail(result, context),
//           );
//         },
//         child: Scaffold(
//           body: _SignInForm(router: router),
//         ),
//       ),
//     );
//   }

//   void _handleSuccessOrFail(Either<UserProfile, FlowyError> result, BuildContext context) {
//     result.fold(
//       (user) => router.pushWelcomeScreen(context, user),
//       (error) => showSnapBar(context, error.msg),
//     );
//   }
// }

// class _SignInForm extends StatelessWidget {
//   final IAuthRouter router;
//   const _SignInForm({
//     Key? key,
//     required this.router,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.center,
//       child: AuthFormContainer(
//         children: [
//           FlowyLogoTitle(
//             title: LocaleKeys.signIn_loginTitle.tr(),
//             logoSize: const Size(60, 60),
//           ),
//           const VSpace(30),
//           const _EmailTextField(),
//           const _PasswordTextField(),
//           _ForgetPasswordButton(router: router),
//           const VSpace(30),
//           const _LoginButton(),
//           const VSpace(10),
//           _SignUpPrompt(router: router),
//           if (context.read<SignInBloc>().state.isSubmitting) ...[
//             const SizedBox(height: 8),
//             const LinearProgressIndicator(value: null),
//           ]
//         ],
//       ),
//     );
//   }
// }

// class _SignUpPrompt extends StatelessWidget {
//   const _SignUpPrompt({
//     Key? key,
//     required this.router,
//   }) : super(key: key);

//   final IAuthRouter router;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Text(LocaleKeys.signIn_dontHaveAnAccount.tr()),
//         TextButton(
//           style: TextButton.styleFrom(
//             textStyle: const TextStyle(fontSize: 12),
//           ),
//           onPressed: () => router.pushSignUpScreen(context),
//           child: Text(LocaleKeys.signUp_buttonText.tr()),
//         ),
//       ],
//       mainAxisAlignment: MainAxisAlignment.center,
//     );
//   }
// }

// class _LoginButton extends StatelessWidget {
//   const _LoginButton({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // return RoundedTextButton(
//     //   title: LocaleKeys.signIn_loginButtonText.tr(),
//     //   height: 48,
//     //   borderRadius: Corners.s10Border,
//     //   color: theme.main1,
//     //   onPressed: () {
//     //     context.read<SignInBloc>().add(const SignInEvent.signedInWithUserEmailAndPassword());
//     //   },
//     // );
//     // FIXME: Will be checked in the future.
//     return TextButton(
//       onPressed: () => context.read<SignInBloc>().add(const SignInEvent.signedInWithUserEmailAndPassword()),
//       child: Text(LocaleKeys.signIn_loginButtonText.tr()),
//     );
//   }
// }

// class _ForgetPasswordButton extends StatelessWidget {
//   const _ForgetPasswordButton({
//     Key? key,
//     required this.router,
//   }) : super(key: key);

//   final IAuthRouter router;

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       style: TextButton.styleFrom(
//         textStyle: const TextStyle(fontSize: 12),
//       ),
//       onPressed: () => router.pushForgetPasswordScreen(context),
//       child: Text(LocaleKeys.signIn_forgotPassword.tr()),
//     );
//   }
// }

// class _PasswordTextField extends StatelessWidget {
//   const _PasswordTextField({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SignInBloc, SignInState>(
//       buildWhen: (previous, current) => previous.passwordError != current.passwordError,
//       builder: (context, state) {
//         return RoundedInputField(
//           obscureText: true,
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           obscureIcon: svg("home/hide"),
//           obscureHideIcon: svg("home/show"),
//           hintText: LocaleKeys.signIn_passwordHint.tr(),
//           errorText: context.read<SignInBloc>().state.passwordError.fold(() => "", (error) => error),
//           onChanged: (value) => context.read<SignInBloc>().add(SignInEvent.passwordChanged(value)),
//         );
//       },
//     );
//   }
// }

// class _EmailTextField extends StatelessWidget {
//   const _EmailTextField({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SignInBloc, SignInState>(
//       buildWhen: (previous, current) => previous.emailError != current.emailError,
//       builder: (context, state) {
//         return RoundedInputField(
//           hintText: LocaleKeys.signIn_emailHint.tr(),
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           errorText: context.read<SignInBloc>().state.emailError.fold(() => "", (error) => error),
//           onChanged: (value) => context.read<SignInBloc>().add(SignInEvent.emailChanged(value)),
//         );
//       },
//     );
//   }
// }

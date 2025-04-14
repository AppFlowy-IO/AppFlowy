import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_magic_link_or_passcode_page.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class ContinueWithEmailAndPassword extends StatefulWidget {
  const ContinueWithEmailAndPassword({super.key});

  @override
  State<ContinueWithEmailAndPassword> createState() =>
      _ContinueWithEmailAndPasswordState();
}

class _ContinueWithEmailAndPasswordState
    extends State<ContinueWithEmailAndPassword> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  final emailKey = GlobalKey<AFTextFieldState>();

  bool _hasPushedContinueWithMagicLinkOrPasscodePage = false;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        final successOrFail = state.successOrFail;
        // only push the continue with magic link or passcode page if the magic link is sent successfully
        if (successOrFail != null) {
          successOrFail.fold(
            (_) => emailKey.currentState?.clearError(),
            (error) => emailKey.currentState?.syncError(
              errorText: error.msg,
            ),
          );
        } else if (successOrFail == null && !state.isSubmitting) {
          emailKey.currentState?.clearError();

          // _pushContinueWithMagicLinkOrPasscodePage(
          //   context,
          //   controller.text,
          // );
        }
      },
      child: Column(
        children: [
          AFTextField(
            key: emailKey,
            controller: controller,
            hintText: LocaleKeys.signIn_pleaseInputYourEmail.tr(),
            radius: 10,
            onSubmitted: (value) => _signInWithEmail(
              context,
              value,
            ),
          ),
          VSpace(theme.spacing.l),
          ContinueWithEmail(
            onTap: () => _signInWithEmail(
              context,
              controller.text,
            ),
          ),
          // VSpace(theme.spacing.l),
          // ContinueWithPassword(
          //   onTap: () => _pushContinueWithPasswordPage(
          //     context,
          //     controller.text,
          //   ),
          // ),
        ],
      ),
    );
  }

  void _signInWithEmail(BuildContext context, String email) {
    if (!isEmail(email)) {
      emailKey.currentState?.syncError(
        errorText: LocaleKeys.signIn_invalidEmail.tr(),
      );
      return;
    }

    context
        .read<SignInBloc>()
        .add(SignInEvent.signInWithMagicLink(email: email));

    _pushContinueWithMagicLinkOrPasscodePage(
      context,
      email,
    );
  }

  void _pushContinueWithMagicLinkOrPasscodePage(
    BuildContext context,
    String email,
  ) {
    if (_hasPushedContinueWithMagicLinkOrPasscodePage) {
      return;
    }

    final signInBloc = context.read<SignInBloc>();

    // push the a continue with magic link or passcode screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: signInBloc,
          child: ContinueWithMagicLinkOrPasscodePage(
            email: email,
            backToLogin: () {
              Navigator.pop(context);

              emailKey.currentState?.clearError();

              _hasPushedContinueWithMagicLinkOrPasscodePage = false;
            },
            onEnterPasscode: (passcode) => signInBloc.add(
              SignInEvent.signInWithPasscode(
                email: email,
                passcode: passcode,
              ),
            ),
          ),
        ),
      ),
    );

    _hasPushedContinueWithMagicLinkOrPasscodePage = true;
  }

  // void _pushContinueWithPasswordPage(
  //   BuildContext context,
  //   String email,
  // ) {
  //   final signInBloc = context.read<SignInBloc>();
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => BlocProvider.value(
  //         value: signInBloc,
  //         child: ContinueWithPasswordPage(
  //           email: email,
  //           backToLogin: () => Navigator.pop(context),
  //           onEnterPassword: (password) => signInBloc.add(
  //             SignInEvent.signInWithEmailAndPassword(
  //               email: email,
  //               password: password,
  //             ),
  //           ),
  //           onForgotPassword: () {
  //             // todo: implement forgot password
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

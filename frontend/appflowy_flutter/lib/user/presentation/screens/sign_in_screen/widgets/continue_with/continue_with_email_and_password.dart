import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_email.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/continue_with/continue_with_magic_link_or_passcode_page.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';
import 'package:universal_platform/universal_platform.dart';

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

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      children: [
        SizedBox(
          height: UniversalPlatform.isMobile ? 38.0 : 40.0,
          child: AFTextField(
            controller: controller,
            hintText: LocaleKeys.signIn_pleaseInputYourEmail.tr(),
            radius: 10,
            onSubmitted: (value) => _pushContinueWithMagicLinkOrPasscodePage(
              context,
              value,
            ),
          ),
        ),
        VSpace(theme.spacing.l),
        ContinueWithEmail(
          onTap: () => _pushContinueWithMagicLinkOrPasscodePage(
            context,
            controller.text,
          ),
        ),
        // Hide password sign in until we implement the reset password / forgot password
        // VSpace(theme.spacing.l),
        // ContinueWithPassword(
        //   onTap: () => _pushContinueWithPasswordPage(
        //     context,
        //     controller.text,
        //   ),
        // ),
      ],
    );
  }

  void _pushContinueWithMagicLinkOrPasscodePage(
    BuildContext context,
    String email,
  ) {
    if (!isEmail(email)) {
      showToastNotification(
        message: LocaleKeys.signIn_invalidEmail.tr(),
        type: ToastificationType.error,
      );
      return;
    }

    final signInBloc = context.read<SignInBloc>();

    signInBloc.add(SignInEvent.signInWithMagicLink(email: email));

    // push the a continue with magic link or passcode screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: signInBloc,
          child: ContinueWithMagicLinkOrPasscodePage(
            email: email,
            backToLogin: () => Navigator.pop(context),
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
  }

  // void _pushContinueWithPasswordPage(
  //   BuildContext context,
  //   String email,
  // ) {
  //   final signInBloc = context.read<SignInBloc>();
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ContinueWithPasswordPage(
  //         email: email,
  //         backToLogin: () => Navigator.pop(context),
  //         onEnterPassword: (password) => signInBloc.add(
  //           SignInEvent.signInWithEmailAndPassword(
  //             email: email,
  //             password: password,
  //           ),
  //         ),
  //         onForgotPassword: () {
  //           // todo: implement forgot password
  //         },
  //       ),
  //     ),
  //   );
  // }
}
